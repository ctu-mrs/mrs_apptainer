# How to enable HW acceleration for GPUs newer than the container's Mesa

## The cause

The container ships **Mesa 21.2.6** (Nov 2021). Any GPU released after that is unknown
to it, so `libGL` silently falls back to **`llvmpipe`** (CPU software rendering) and
Gazebo / RViz / PlotJuggler consume 100% CPU.

**Why not just bind the host's Mesa?** The container is glibc 2.31 (focal); an
Ubuntu 24.04 host is glibc 2.39. Host Mesa `.so` files need `GLIBC_2.32+` symbols
and will not load. Building in-container is the only route.

## Prerequisite: do NOT bind-mount `/dev/dri`

If your wrapper's `MOUNTS` array contains

```bash
"type=bind" "/dev/dri" "/dev/dri"   # <-- DELETE THIS LINE
```

**remove it.** Apptainer applies `nodev` to user bind mounts, and the kernel returns
`EACCES` when opening a character device on a `nodev` mount. Apptainer already exposes the host's
full `/dev` (without `nodev`), so `/dev/dri` is present without any bind.

## Building the Mesa 24.2.8 library for Ubuntu 20.04

The magic happens in the script `scripts/build_mesa.sh`, which is to be run within the container and handles actually building the driver.
By the default, it produces a single artifact that works on both AMD and Intel machines. Override the `GALLIUM_DRIVERS=radeonsi,iris,swrast` variable it if you want a smaller build.

Run from the repo root **on the host**:

```bash
IMG=images/mrs_uav_system_modified # replace this with a different name, if applicable

# 1. create a writable sandbox (~1-2 min, ~9 GB) + its bind mountpoints
apptainer build --fakeroot --sandbox ${IMG}_sbx ${IMG}.sif
apptainer exec --fakeroot --writable ${IMG}_sbx mkdir -p /opt/mesa /mnt/scripts

# 2. run the build script within the sandbox to build Mesa to opt_mesa
rm -rf opt_mesa && mkdir -p opt_mesa
apptainer exec --fakeroot --writable \
  --bind "$PWD/opt_mesa:/opt/mesa" \
  --bind "$PWD/scripts:/mnt/scripts" \
  ${IMG}_sbx \
  bash /mnt/scripts/build_mesa.sh
```

**Disk:** ~4 GB transient for a `radeonsi`-only build, or ~7 GB if `iris` is in the driver
set. Cca ~150 MB installed. The script refuses to start below 10 GB free disc space (`MIN_FREE_GB`).

## Using the driver

Add to the `MOUNTS` array in your wrapper:

```bash
"type=bind" "$MRS_APPTAINER_PATH/opt_mesa" "/opt/mesa" # bind the Mesa driver
```

Add to the end of `mount/apptainer_bashrc.sh` or `mount/apptainer_zshrc.sh`:

```bash
if [ -d /opt/mesa/lib/x86_64-linux-gnu/dri ]; then
  export LD_LIBRARY_PATH="/opt/mesa/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"
  export LIBGL_DRIVERS_PATH="/opt/mesa/lib/x86_64-linux-gnu/dri"
  export __EGL_VENDOR_LIBRARY_DIRS="/opt/mesa/share/glvnd/egl_vendor.d"
fi
```

The `/opt/mesa` directory must come *before* `/usr/lib/x86_64-linux-gnu` in `LD_LIBRARY_PATH`.
Check with: `echo $LD_LIBRARY_PATH | tr : '\n' | grep -n 'opt/mesa\|usr/lib/x86'`

Then restart any running container.

## Testing that it works

`glxinfo` is not installed in the container, so the build installs a small
equivalent, `glxprobe` (source: `scripts/glxprobe.c`):

```bash
/opt/mesa/bin/glxprobe
```

**Good output:** a hardware renderer, no `libGL error` lines:

```
direct rendering: Yes
GL_VENDOR       : AMD
GL_RENDERER     : AMD Radeon RX 7900 XTX (radeonsi, navi31, LLVM 18.1.8, DRM 3.64, 6.17.0-29-generic)
GL_VERSION      : 4.6 (Compatibility Profile) Mesa 24.2.8
```

**Bad output:** still software:

```
libGL error: failed to load driver: radeonsi
GL_RENDERER     : llvmpipe (LLVM 12.0.0, 256 bits)
```

Note `direct rendering: Yes` appears in **both** cases — it means DRI3 is working,
not that you have hardware acceleration. Judge by `GL_RENDERER`.

Final check: start a simulation session with RViz and watch `htop`. If the RViz
process sits below 100% CPU, it is rendering on the GPU.

## Cleanup

Once verified, the build sandbox (`images/*_sbx`, ~9 GB) is no longer needed —
`opt_mesa` is self-contained. Keep it if you expect to rebuild.

## Tested with

| GPU                                      | PCI id      | ISA     | Needs Mesa |
|------------------------------------------|-------------|---------|------------|
| AMD Navi 31 / RDNA3 (RX 7900 XT/XTX/GRE) | `1002:744c` | gfx1100 | >= 22.3    |
| Intel Lunar Lake / Xe2 (Arc 130V/140V)   | `8086:64a0` | —       | >= 24.2.2  |
