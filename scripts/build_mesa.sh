#!/usr/bin/env bash
#
# build_mesa.sh
# -------------
# Builds a modern Mesa for the MRS Apptainer container so that HARDWARE OpenGL works
# on GPUs that are newer than the container's stock Mesa 21.2.6 (Nov 2021).
#
# Supersedes build_mesa_xe2.sh, which was hardcoded to Intel 'iris'. A single Mesa
# build can contain several gallium drivers; the right one is selected at RUNTIME by
# PCI id, so one artifact serves every machine. Set GALLIUM_DRIVERS to taste.
#
# WHY THIS IS NEEDED
#   Only the container's USERSPACE Mesa is stale -- the kernel driver lives on the
#   host and is current. Mesa 21.2.6 predates recent GPUs, so it refuses their PCI
#   ids and OpenGL silently falls back to 'llvmpipe' (CPU) -> slow Gazebo/RViz/PlotJuggler.
#
#   Known-bad pairings this fixes:
#     AMD Navi 31 / RDNA3 (gfx1100, PCI 1002:744c)  needs Mesa >= 22.3
#       stock radeonsi tops out at gfx1030 and reports:
#       "amdgpu: unknown (family_id, chip_external_rev): (145, 1)"
#     AMD Raphael iGPU   (gfx1036, PCI 1002:164e)  needs Mesa >= 22.0
#     Intel Lunar Lake / Xe2 (PCI 8086:64a0, 'xe') needs Mesa >= 24.2.2
#
#   The host's own Mesa CANNOT simply be bind-mounted: the container is glibc 2.31
#   (focal) and a 24.04 host is glibc 2.39, so those .so files will not load.
#
# WHERE TO RUN
#   Inside a WRITABLE + FAKEROOT session of the MRS image (needed for apt + root build).
#   Mesa installs to the bind-mounted $PREFIX (=/opt/mesa), which lives on the HOST, so
#   the result survives after the throwaway build sandbox is deleted.
#
# RUNBOOK (from the repo root, on the HOST -- apptainer is not available in-container)
#
#   IMG=images/mrs_uav_system_modified
#
#   # 1. one-off: create the writable sandbox (~1-2 min, ~9 GB) and its mountpoints
#   apptainer build --fakeroot --sandbox ${IMG}_sbx ${IMG}.sif
#   apptainer exec --fakeroot --writable ${IMG}_sbx mkdir -p /opt/mesa /mnt/scripts
#
#   # 2. build into a STAGING dir, so a failure cannot break a working /opt/mesa.
#   #    Binding the staging dir at /opt/mesa keeps the compiled-in prefix correct,
#   #    which a plain "install elsewhere then mv" would not.
#   rm -rf opt_mesa_build && mkdir -p opt_mesa_build
#   apptainer exec --fakeroot --writable \
#     --bind "$PWD/opt_mesa_build:/opt/mesa" \
#     --bind "$PWD/scripts:/mnt/scripts" \
#     ${IMG}_sbx \
#     bash /mnt/scripts/build_mesa.sh
#
#   # 3. swap into place ONLY on success
#   rm -rf opt_mesa.old && [ -d opt_mesa ] && mv opt_mesa opt_mesa.old
#   mv opt_mesa_build opt_mesa
#
#   # 4. wire it up: uncomment the /opt/mesa bind in your wrapper's MOUNTS array,
#   #    restart the container, then verify with
#   #      /opt/mesa/bin/glxprobe
#
# TUNABLES (env vars)
#   GALLIUM_DRIVERS   default radeonsi,iris,swrast   (swrast = llvmpipe fallback; keep it)
#   MESA_VERSION      default 24.2.8   (last of the 24.2 series; safe with focal gcc 9)
#   LIBDRM_VERSION    default 2.4.122  (Mesa 24.2 needs libdrm >= 2.4.119)
#   LLVM_VER          default 18       (matches the libLLVM-18 already in the image)
#   PREFIX            default /opt/mesa (bind this to a host dir so it persists)
#   BUILD_SPIRV_TOOLS default 1        (0 = skip; forced to 1 when iris is requested)
#   MIN_FREE_GB       default 10       (preflight guard; peak ~4 GB, or ~7 GB with iris)
#   JOBS              default $(nproc)
#
set -euo pipefail

GALLIUM_DRIVERS="${GALLIUM_DRIVERS:-radeonsi,iris,swrast}"
MESA_VERSION="${MESA_VERSION:-24.2.8}"
LIBDRM_VERSION="${LIBDRM_VERSION:-2.4.122}"
SPIRV_TAG="${SPIRV_TAG:-vulkan-sdk-1.3.290.0}"   # SPIRV-Headers/Tools tag (Mesa 24.2 era)
SPIRV_LLVM_BRANCH="${SPIRV_LLVM_BRANCH:-v18.1.1}"  # frozen tag for LLVM 18.1 (NOT the moving llvm_release_180 branch tip)
LLVM_VER="${LLVM_VER:-18}"
PREFIX="${PREFIX:-/opt/mesa}"
BUILD_SPIRV_TOOLS="${BUILD_SPIRV_TOOLS:-1}"
MIN_FREE_GB="${MIN_FREE_GB:-10}"
JOBS="${JOBS:-$(nproc)}"
BUILD_ROOT="${BUILD_ROOT:-/tmp/mesa-build}"

log()  { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
die()  { printf '\n\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "must run as root -- start the container with --fakeroot --writable"

MULTIARCH="lib/x86_64-linux-gnu"
export DEBIAN_FRONTEND=noninteractive

# Derive the libdrm backends from the requested gallium drivers. Building a driver
# without its libdrm backend fails at configure time.
#   iris     -> libdrm_intel
#   radeonsi -> libdrm_amdgpu AND libdrm_radeon.
# The second one is not a typo and not optional: Mesa compiles the legacy 'radeon'
# winsys alongside the amdgpu one (it drives old SI/CIK parts through the radeon
# kernel driver), so meson hard-requires libdrm_radeon even on an RDNA3-only box.
# Omitting it fails with: ERROR: Dependency "libdrm_radeon" not found.
case ",$GALLIUM_DRIVERS," in (*,radeonsi,*) DRM_AMDGPU=enabled; DRM_RADEON=enabled;;
                            (*)             DRM_AMDGPU=disabled; DRM_RADEON=disabled;; esac
case ",$GALLIUM_DRIVERS," in (*,iris,*)     DRM_INTEL=enabled;;  (*) DRM_INTEL=disabled;;  esac

# Does this driver set drag in Mesa's OpenCL-C compiler ("clc")?
#
# YES for iris. '-Dintel-clc' is a combo whose choices are enabled/system/auto --
# there is NO 'disabled' -- and with iris in the driver list 'auto' resolves to
# ENABLED. intel-clc then hard-requires clang + LLVMSPIRVLib, the latter supplied
# only by SPIRV-LLVM-Translator, which focal does not package.
# Symptom when missing: ERROR: Dependency "LLVMSPIRVLib" not found  (meson.build:1890)
# Tell-tale in the log: the LLVM module list gains libdriver/frontenddriver/
# frontendhlsl/windowsdriver/coroutines -- that is the clc module set.
#
# NO for a radeonsi-only build, which is why this is conditional: it costs ~3 GB
# and ~20 min, and there is no reason to pay it on an AMD-only machine.
case ",$GALLIUM_DRIVERS," in (*,iris,*) NEED_CLC=1;; (*) NEED_CLC=0;; esac

# The translator needs SPIRV-Headers, which the SPIRV-Tools stage provides.
[ "$NEED_CLC" = "1" ] && BUILD_SPIRV_TOOLS=1

log "Configuration"
cat <<EOF
  gallium drivers : $GALLIUM_DRIVERS
  libdrm backends : amdgpu=$DRM_AMDGPU radeon=$DRM_RADEON intel=$DRM_INTEL
  needs clc       : $NEED_CLC  (1 = also builds clang deps + SPIRV-LLVM-Translator)
  mesa            : $MESA_VERSION
  libdrm          : $LIBDRM_VERSION
  llvm            : $LLVM_VER
  prefix          : $PREFIX
  jobs            : $JOBS
EOF

# ---------------------------------------------------------------- 0. preflight
# A 40-minute build dying on ENOSPC is the most annoying failure mode here.
FREE_GB=$(df -BG --output=avail "$BUILD_ROOT" 2>/dev/null || df -BG --output=avail /tmp)
FREE_GB=$(echo "$FREE_GB" | tail -1 | tr -dc '0-9')
if [ -n "$FREE_GB" ] && [ "$FREE_GB" -lt "$MIN_FREE_GB" ]; then
  die "only ${FREE_GB} GB free where the build tree goes, need >= ${MIN_FREE_GB} GB (peak ~3.5 GB).
       Free some space, or point BUILD_ROOT at a roomier filesystem."
fi

# radeonsi is an LLVM-backed driver: the shader compiler must know the target ISA.
# Checking now beats discovering it after Mesa builds fine but refuses the GPU.
if [ "$DRM_AMDGPU" = "enabled" ]; then
  # Consume the WHOLE stream. The obvious `strings ... | grep -q gfx1100` is wrong
  # under `set -o pipefail`: grep -q exits at the first match, strings then dies of
  # SIGPIPE (141), pipefail propagates that, and the test reports failure *because*
  # the match succeeded. It also fires on a genuine miss -- i.e. it warns always.
  # grep -o reads to EOF, so there is no early close and no SIGPIPE.
  LLVM_SO="/usr/lib/x86_64-linux-gnu/libLLVM-${LLVM_VER}.so.1"
  LLVM_ISA="$(strings "$LLVM_SO" 2>/dev/null | grep -oE 'gfx[0-9]+' | sort -u || true)"
  case "$LLVM_ISA" in
    *gfx1100*) log "libLLVM-${LLVM_VER} advertises gfx1100 (RDNA3) -- OK" ;;
    "")        log "WARNING: could not read $LLVM_SO -- skipping the RDNA3 ISA check." ;;
    *)         log "WARNING: libLLVM-${LLVM_VER} does not advertise gfx1100; RDNA3 shaders may not compile." ;;
  esac
fi

# ---------------------------------------------------------------- 1. build deps
# clang/libclang/libclc are installed ONLY when the driver set needs clc (i.e. iris),
# since they exist purely to satisfy intel-clc. A radeonsi-only build skips them.
CLC_PKGS=()
if [ "$NEED_CLC" = "1" ]; then
  CLC_PKGS=("clang-${LLVM_VER}" "libclang-${LLVM_VER}-dev" "libclc-${LLVM_VER}-dev")
fi

log "Installing build dependencies (apt)"
apt-get update
apt-get install -y --no-install-recommends \
  build-essential pkg-config ca-certificates curl xz-utils git \
  python3-pip python3-setuptools python3-mako \
  flex bison \
  "llvm-${LLVM_VER}-dev" "llvm-${LLVM_VER}-tools" \
  ${CLC_PKGS[@]+"${CLC_PKGS[@]}"} \
  libelf-dev libexpat1-dev zlib1g-dev libzstd-dev libpciaccess-dev \
  libx11-dev libx11-xcb-dev libxext-dev libxdamage-dev libxfixes-dev libxrandr-dev \
  libxcb1-dev libxcb-dri3-dev libxcb-dri2-0-dev libxcb-present-dev libxcb-sync-dev \
  libxcb-glx0-dev libxcb-randr0-dev libxcb-shm0-dev libxshmfence-dev libxxf86vm-dev

log "Installing meson + ninja + cmake (focal's apt versions are too old)"
pip3 install --upgrade "meson>=1.4,<1.6" ninja cmake

export PATH="/usr/local/bin:/usr/lib/llvm-${LLVM_VER}/bin:${PATH}"
command -v "llvm-config-${LLVM_VER}" >/dev/null 2>&1 || \
  ln -sf "/usr/lib/llvm-${LLVM_VER}/bin/llvm-config" /usr/local/bin/llvm-config

mkdir -p "$BUILD_ROOT" "$PREFIX"
export PKG_CONFIG_PATH="$PREFIX/$MULTIARCH/pkgconfig:$PREFIX/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
export LD_LIBRARY_PATH="$PREFIX/$MULTIARCH:${LD_LIBRARY_PATH:-}"

# ---------------------------------------------------------------- 2. libdrm
log "Building libdrm ${LIBDRM_VERSION} (amdgpu=$DRM_AMDGPU radeon=$DRM_RADEON intel=$DRM_INTEL)"
cd "$BUILD_ROOT"
[ -f "libdrm-${LIBDRM_VERSION}.tar.xz" ] || \
  curl -fLO "https://dri.freedesktop.org/libdrm/libdrm-${LIBDRM_VERSION}.tar.xz"
rm -rf "libdrm-${LIBDRM_VERSION}"; tar xf "libdrm-${LIBDRM_VERSION}.tar.xz"
cd "libdrm-${LIBDRM_VERSION}"
meson setup build --prefix="$PREFIX" --libdir="$MULTIARCH" --buildtype=release \
  -Dintel="$DRM_INTEL" -Damdgpu="$DRM_AMDGPU" -Dradeon="$DRM_RADEON" \
  -Dnouveau=disabled \
  -Dvmwgfx=disabled -Dvc4=disabled -Dfreedreno=disabled -Detnaviv=disabled -Dtests=false
meson compile -C build -j "$JOBS"
meson install -C build

# ---------------------------------------------------------- 2b. SPIR-V tools
# Kept because the Intel build path was verified to want it. Cheap (~400 MB, few
# minutes). Mesa reports it as: Run-time dependency spirv-tools found: YES 2024.3.1
if [ "$BUILD_SPIRV_TOOLS" = "1" ]; then
  log "Building SPIRV-Headers + SPIRV-Tools (${SPIRV_TAG})"
  cd "$BUILD_ROOT"
  [ -d SPIRV-Headers ] || git clone --depth 1 -b "$SPIRV_TAG" \
    https://github.com/KhronosGroup/SPIRV-Headers.git
  cmake -S SPIRV-Headers -B SPIRV-Headers/build \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_BUILD_TYPE=Release
  cmake --build SPIRV-Headers/build --target install -j "$JOBS"

  [ -d SPIRV-Tools ] || git clone --depth 1 -b "$SPIRV_TAG" \
    https://github.com/KhronosGroup/SPIRV-Tools.git
  cmake -S SPIRV-Tools -B SPIRV-Tools/build \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_BUILD_TYPE=Release \
    -DSPIRV_SKIP_TESTS=ON -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DSPIRV-Headers_SOURCE_DIR="$BUILD_ROOT/SPIRV-Headers"
  cmake --build SPIRV-Tools/build --target install -j "$JOBS"
fi

# ------------------------------------------------ 2c. SPIRV-LLVM-Translator
# Provides LLVMSPIRVLib, which intel-clc hard-requires. Not packaged for focal, so
# it is built from the tag matching LLVM ${LLVM_VER}. This is the expensive stage
# (~3 GB, ~20 min) because it links against LLVM -- hence it is skipped entirely
# unless the driver set actually pulls in clc (see NEED_CLC above).
if [ "$NEED_CLC" = "1" ]; then
  log "Building SPIRV-LLVM-Translator (${SPIRV_LLVM_BRANCH}) -- needed by intel-clc for iris"
  cd "$BUILD_ROOT"
  rm -rf SPIRV-LLVM-Translator   # force a fresh checkout of the pinned tag, not a stale clone
  git clone --depth 1 -b "$SPIRV_LLVM_BRANCH" \
    https://github.com/KhronosGroup/SPIRV-LLVM-Translator.git
  cmake -S SPIRV-LLVM-Translator -B SPIRV-LLVM-Translator/build \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DLLVM_DIR="/usr/lib/llvm-${LLVM_VER}/lib/cmake/llvm" \
    -DCMAKE_PREFIX_PATH="$PREFIX" \
    -DLLVM_EXTERNAL_SPIRV_HEADERS_SOURCE_DIR="$BUILD_ROOT/SPIRV-Headers" \
    -DLLVM_SPIRV_INCLUDE_TESTS=OFF
  cmake --build SPIRV-LLVM-Translator/build --target install -j "$JOBS"
fi

# ---------------------------------------------------------------- 3. Mesa
log "Building Mesa ${MESA_VERSION} [${GALLIUM_DRIVERS}]"
cd "$BUILD_ROOT"
[ -f "mesa-${MESA_VERSION}.tar.xz" ] || \
  curl -fLO "https://archive.mesa3d.org/mesa-${MESA_VERSION}.tar.xz"
rm -rf "mesa-${MESA_VERSION}"; tar xf "mesa-${MESA_VERSION}.tar.xz"
cd "mesa-${MESA_VERSION}"

# -Dllvm is REQUIRED by radeonsi (shader compiler) and by swrast/llvmpipe.
# -Dvideo-codecs= and the gallium-va/vdpau/xa disables keep libva/libvdpau out of
# the dependency graph; nothing in RViz/Gazebo/PlotJuggler needs them.
#
# -Dintel-clc is a COMBO whose only choices are enabled/system/auto -- there is no
# "disabled", so passing that fails outright. 'auto' resolves to ENABLED whenever
# iris is in the driver list, which is what drags in clang + LLVMSPIRVLib (see the
# NEED_CLC block near the top). It only stays unbuilt for a radeonsi-only build.
# Do NOT conclude intel-clc was skipped just because no intel_clc binary appears in
# $PREFIX/bin -- it is a build-time tool and meson never installs it.
meson setup build --prefix="$PREFIX" --libdir="$MULTIARCH" --buildtype=release \
  -Dgallium-drivers="$GALLIUM_DRIVERS" \
  -Dvulkan-drivers= \
  -Dintel-clc=auto \
  -Dplatforms=x11 \
  -Dglx=dri -Ddri3=enabled -Degl=enabled -Dgbm=enabled \
  -Dopengl=true -Dgles1=disabled -Dgles2=enabled \
  -Dllvm=enabled -Dshared-llvm=enabled \
  -Dgallium-va=disabled -Dgallium-vdpau=disabled -Dgallium-xa=disabled \
  -Dvalgrind=disabled -Dlibunwind=disabled -Dvideo-codecs=
meson compile -C build -j "$JOBS"
meson install -C build

# ---------------------------------------------------------- 4. verify + probe
# Mesa 24.x uses a "megadriver": every *_dri.so is a symlink to one shared object.
log "Verifying installed drivers"
DRI_DIR="$PREFIX/$MULTIARCH/dri"
[ -d "$DRI_DIR" ] || die "no dri directory at $DRI_DIR -- install did not happen"
ls -l "$DRI_DIR"
IFS=',' read -ra _WANT <<< "$GALLIUM_DRIVERS"
for d in "${_WANT[@]}"; do
  [ "$d" = "swrast" ] && continue
  [ -e "$DRI_DIR/${d}_dri.so" ] || die "${d}_dri.so missing -- '$d' did not actually build"
done

# glxinfo is not installed in the container, so ship a tiny equivalent.
if [ -f /mnt/scripts/glxprobe.c ]; then
  log "Building glxprobe into $PREFIX/bin"
  mkdir -p "$PREFIX/bin"
  gcc -O1 -o "$PREFIX/bin/glxprobe" /mnt/scripts/glxprobe.c -lGL -lX11
fi

cat <<EOF

$(log "SUCCESS -- Mesa ${MESA_VERSION} [${GALLIUM_DRIVERS}] installed to ${PREFIX}")

Next: swap the staging dir into place on the HOST, bind it at /opt/mesa in your
wrapper, restart the container, then run

  /opt/mesa/bin/glxprobe

Expect a hardware renderer (e.g. "AMD Radeon RX 7900 XTX (radeonsi, gfx1100, ...)")
and NOT 'llvmpipe'.
EOF
