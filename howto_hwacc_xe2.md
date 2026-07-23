# How to enable HW acceleration for modern Intel Iris GPUs with the `xe` driver

## Building the Mesa 24.2.8 driver for Ubuntu 20.04

The magic happens in the script `scripts/build_mesa_xe2.sh`, which is to be run within the container and handles actually building the driver.

In this folder, run the following commands:
```bash
IMG=images/mrs_uav_system_modified # change for the image you actually use

# create a writable sandbox from the .sif (~1-2 min, needs ~3 GB)
apptainer build --fakeroot --sandbox ${IMG}_sbx ${IMG}.sif

# create a dir on the host that will hold the built Mesa (persists outside the sandbox)
mkdir -p opt_mesa

# create the bind mountpoints INSIDE the sandbox
apptainer exec --fakeroot --writable ${IMG}_sbx mkdir -p /opt/mesa /mnt/scripts

# build (apt deps land in the sandbox; Mesa installs to ./opt_mesa via the bind)
apptainer exec --fakeroot --writable \
  --bind "$PWD/opt_mesa:/opt/mesa" \
  --bind "$PWD/scripts:/mnt/scripts" \
  ${IMG}_sbx \
  bash /mnt/scripts/build_mesa_xe2.sh
```

## Using the driver

In your wrapper script, make sure to bind the `opt_mesa` folder containing the built driver into `/opt/mesa`, i.e. add the line
```bash
"type=bind" "$MRS_APPTAINER_PATH/opt_mesa" "/opt/mesa" # bind the Mesa driver
```
to the `MOUNTS` array.

Next, add the following lines to `mount/99-mrs_env.sh`
```bash
# Hardware OpenGL for Intel Lunar Lake / Xe2 (Arc 130V/140V, PCI 8086:64a0).
# The container's stock Mesa 21.2.6 is too old for this GPU and falls back to
# llvmpipe (software). Use the custom Mesa 24.2 bind-mounted at /opt/mesa instead.
# PREPEND to LD_LIBRARY_PATH so ROS/Gazebo library paths are preserved.
if [ -d /opt/mesa/lib/x86_64-linux-gnu/dri ]; then
  export LD_LIBRARY_PATH="/opt/mesa/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"
  export LIBGL_DRIVERS_PATH="/opt/mesa/lib/x86_64-linux-gnu/dri"
  export __EGL_VENDOR_LIBRARY_DIRS="/opt/mesa/share/glvnd/egl_vendor.d"
fi
```
and the following lines to `mount/apptainer_bashrc.sh` (change if you're using zsh of course)
```bash
# custom Mesa 24.2 (Intel Lunar Lake / Xe2 hardware OpenGL) must take precedence over the
# container's stock Mesa in /usr/lib, so prepend it AFTER the block above (which also
# prepends /usr/lib). Without this, the old libGL wins and can't drive the 'xe' GPU.
if [ -d /opt/mesa/lib/x86_64-linux-gnu/dri ]; then
  export LD_LIBRARY_PATH="/opt/mesa/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH"
  export LIBGL_DRIVERS_PATH="/opt/mesa/lib/x86_64-linux-gnu/dri"
fi
```
These will make sure that the driver is used in newly launched apptainers

Finally, restart any container you may be running.
It should now run with the new Mesa driver that enables HW acceleration for Gazebo, Rviz, PlotJuggler, etc.

## Testing that it works

After restarting the apptainer, run
```bash
/opt/mesa/glxinfo -B | grep -iE 'renderer|direct'
```
It should print something like
```bash
direct rendering: Yes
Extended renderer info (GLX_MESA_query_renderer):
OpenGL renderer string: Mesa Intel(R) Graphics (LNL)
```

The final check is to start a simulation session with Rviz and check `htop` for the CPU load... if it's below 100% for the Rviz process, then it's using HW rendering.

## Caveats

This may or may not work for other GPUs than the Intel Iris with the `xe` driver.
Similar limitation w.r.t. software - so far, I tested it with Rviz and PlotJuggler.
