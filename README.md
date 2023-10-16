# MRS Singularity

This repository provides a way to run the MRS UAV System in a [Singularity](https://sylabs.io/guides/3.5/user-guide/introduction.html) container.
Singularity allows you, an average user, to use our system without installing it into your system and thus cluttering your OS with our software.
Moreover, the following benefits arise when using Singularity containers:

* The provided image won't change on its own and, therefore, will work and be compatible even when you update or reinstall your system.
* The provided image will run across Ubuntu versions. You run, e.g., our ROS Noetic-based image on the 18.04 host system.
* The provided image can be backed up easily by copy-and-pasting a single file.
* The provided image can be altered and saved again, allowing you to store our system's particular configuration for later testing.

**Why Singularity and not just Docker?**

* Singularity integrates more into the host's system: you will get your user in the container.
* You can get your `$HOME` mounted into the container if needed (NOT on by default).
* With the `$HOME` mounted, the programs running inside the container can use your host's computer config files.
* Running GUI applications is much more straightforward: it just works.

# Prerequisities

MRS Singularity will run on the following operating systems

* Linux
* Windows 10, windows 11
  * requires WSL instaled
  * <details>
    <summary>>>> Installation quick guide <<<</summary>

      * Install WSL (`wsl --install` in power shell).
      * Install "Ubuntu 20.04" using the Microsoft Store.
      * Download and install [VcXsrv](https://sourceforge.net/projects/vcxsrv/) (that is an X-server client for Windows... to see the windows from within Ubuntu)
      * Run the Terminal from the start menu and launch a new terminal with Ubuntu 20.04
      * **Update**: It might be necessary to export the `$DISPLAY` variable inside the container. Follow, e.g., this manual here [link](https://stackoverflow.com/questions/61860208/running-graphical-linux-desktop-applications-from-wsl-2-error-e233-cannot-op). Exporting the variable should be done using the `.bashrc` file, which is located in `mrs_singularity/mount/singularity_bashrc.sh`.
      * The server should be started by running: `vcxsrv.exe -ac -multiwindow`
      * `sudo apt update && sudo apt upgrade && sudo apt install gedit` (installing gedit is just one way to force it to install x-server-related stuff. Maybe there is a better way.)
      * run gedit to verify that GUI will show up
      * follow this README further to build a singularity image, alternatively, you can copy the image from, e.g., an external hard drive. (in WSL Linux, run `explorer.exe .` which will allow you to copy data between Windows and Linux

    </details>

## Quick Start Guide (Linux)

1. Install Singularity - [install/install_singularity.sh](./install/install_singularity.sh).
2. Create a Singularity image of the MRS UAV System. _This can take up to 30 minutes, depending on your internet connection and computer resources_.

| **build script**                                       | **description**                                                           |
|--------------------------------------------------------|---------------------------------------------------------------------------|
| [recipes/stable/build.sh](recipes/stable/build.sh)     | installs from the [stable PPA](https://github.com/ctu-mrs/ppa-stable)     |
| [recipes/unstable/build.sh](recipes/unstable/build.sh) | installs from the [unstable PPA](https://github.com/ctu-mrs/ppa-unstable) |

3. Copy the [example_wrapper.sh](./example_wrapper.sh) (versioned example) into `wrapper.sh` (.gitignored). It will allow you to configure the wrapper for yourself.
4. Run the Singularity container by issuing:
```bash
./wrapper.sh
```

Now, you should see the terminal prompt of the singularity container, similar to this:
```bash
[MRS Singularity] user@hostname:~$
```

You can test whether the MRS UAV System is operational by starting the [example Gazebo simulation session](https://ctu-mrs.github.io/docs/simulation/gazebo/gazebo/howto.html).
```bash
[MRS Singularity] user@hostname:~$ roscd mrs_uav_gazebo_simulation/tmux/one_drone
[MRS Singularity] user@hostname:~$ ./start.sh
```
5. To compile your software with the MRS UAV System dependencies, start by placing your packages into the `<mrs_singularity>/user_ros_workspace/src` folder of this repository.
As an example, let's clone the [Example Tracker Plugin](https://github.com/ctu-mrs/example_tracker_plugin).
```bash
cd user_ros_workspace/src
git clone https://github.com/ctu-mrs/example_tracker_plugin.git
```
This host's computer folder is mounted into the container as `~/user_ros_workspace`.
You can then run the singularity container, [init the workspace](https://ctu-mrs.github.io/docs/software/catkin/managing_workspaces/managing_workspaces.html), and build the packages by:
```bash
./wrapper.sh
[MRS Singularity]$ cd ~/user_ros_workspace/
[MRS Singularity]$ catkin init
[MRS Singularity]$ catkin build
```
Although the workspace resides on your host computer, the software cannot be run by the host system.
The container fulfills the dependencies.
To start the software, do so from within the container:
```bash
[MRS Singularity] user@hostname:~$ cd ~/user_ros_workspace/src/examle_tracker_plugin/tmux
[MRS Singularity] user@hostname:~$ ./start.sh
```

## Default behavior

* The container is run **without** mounting the host's `$HOME`.
* The container's `/tmp` is mounted into host's `/tmp/singularity_tmp`.

## Repository structure

```
.
├── images
├── install
├── mount
├── overlays
├── README.md
├── recipes
├── scripts
├── user_ros_workspace
└── example_wrapper.sh
```

<details>
<summary>>>> Click to expand <<<</summary>

### example_wrapper.sh

Example of our singularity wrapper script.
Use this to start our container.
The script contains a _user configuration section_.

### scripts

Shell scripts that automate some of the work with Singularity.
All the scripts expect to be run from within the _scripts_ folder.

### images

Contains Singularity images (.gitignored)

### install

Installation scripts.

### user_ros_workspace

ROS workspace folder mounted into the container's `~/user_ros_workspace`.
Use this for storing and compiling your packages.
The packages need to be placed directly into `user_ros_workspace/src` without linking.
The links do not translate into the container.
The contents of the `user_ros_workspace` folder are .gitignored.

### mount

Folder with MRS scripts and shell additions are mounted dynamically into the container as `/opt/mrs/host`.
The folder contains the `.bashrc`, `.profile`, and `.zshrc` that are sourced within the container when running it without the host's `$HOME`.
You can modify these to change the ROS behavior.

### ovelays

Place for Singularity overlay images (.gitignored).

### recipes

Singularity recipes.
</details>

## Enabling nVidia graphics`

Edit the parameter (false -> true)
```bash
USE_NVIDIA
```
in the `wrapper.sh` script to enable nVidia graphics integration.
Beware, it is not guaranteed to work on all systems.
Typical issues revolve around the `version 'GLIBC_2.34' not found` error.

## Mounting host's $HOME

The host's `$HOME` directory is not mounted by default.
To mount the host's `$HOME` into the container, run the `./wrapper.sh` with `CONTAINED=false`.
However, this will make the container's shells to source your shell RC file.
To make the container run with the internal ROS environment, put the following code snippet into your `.bashrc` and/or `.zshrc`.
`<mrs_singularity>` stands for the path to where you have cloned this repository.

**BASH**:
```bash
if [ -n "$SINGULARITY_NAME" ]; then
  source <mrs_singularity>/mount/singularity_bashrc.sh
fi
```

**ZSH**:
```bash
if [ -n "$SINGULARITY_NAME" ]; then
  source <mrs_singularity>/mount/singularity_zshrc.sh
fi
```

## Installing additional stuff to a container

There are several ways to alter the provided container.

### Creating persistent overlay (preferred)

A persistent overlay is an additional image that is dynamically loaded and _attached_ to the provided container.
Using an overlay is the most straightforward way to store changes to the container, e.g., additional installed software and libraries.

1. Create the overlay image using the provided script: [./scripts/create_overlay.sh](./scripts/create_overlay.sh) (choose the overlay size in the script)
2. Start `wrapper.sh` with `OVERLAY=TRUE`.
3. Run `sudo ./wrapper` to install additional stuff. Remember not to put stuff in `$HOME`.

Optinally, the overlay can be embedded into the provided image by running [./scripts/embed_overlay.sh](./scripts/embed_overlay.sh).
Embedding an overlay might be helpful, e.g., when providing the altered image to a third party.

### Bootstrapping into a new container (preferred in later stages)

Although overlays are great, they pose disadvantages: they cannot be versioned, documented, and automated.
That can be overcome by bootstrapping the provided image into a new Singularity image using a custom Singularity recipe.

**PROS**:

The preferred way is to bootstrap the existing container into a new container with a custom recipe file.
Creating a customized image allows you to be independent on the input container, receive updates and be compatible with the provided container.

**CONS:**

Building a new container takes longer.
Therefore, finding out what you need to do is tedious.
However, finding what actions you need to take can be done by using an overlay or modifying the container directly.
See the manual down below.

An example recipe, that creates a new image with [Visual Studio Code]() can be found in [./recipes/05_user_modifications](./recipes/05_user_modifications).
User modifications can also be added directly by modifying one of the main recipes.
However, creating a custom recipe for modifying an already existing image is a more future-proof solution.

### Modifying an existing container (possible but not recommended)

If you need to change the container (even removing files), you can do that by following these steps:

1. convert it to the _sandbox_ container ([./scripts/convert_sandbox.sh](./scripts/convert_sandbox.sh), `TO_SANBOX=true`):
```bash
sudo singularity build --sandbox <final-container-directory> <input-file.sif>
```
3. run `./wrapper.sh` with `WRITABLE=true` and `FAKEROOT=true`,
4. modify the container, install stuff, etc.,
5. convert back to `.sif`, ([./scripts/convert_sandbox.sh](./scripts/convert_sandbox.sh), `TO_SANBOX=false`):
```bash
sudo singularity build <output-file.sif> <input-container-directory/>
```

# Troubleshooting

## General runtime problems

If something is behaving strangly, it might be because your `$HOME` within the container is somehow corrupted.
The first go-to solution is to clean the container's `HOME` and `TMP`.
These folders are located in `/tmp/singularity` of your machine.
```bash
rm -rf /tmp/singularity
```

## No loop devices available

If you encounter "**No loop devices available**" problem while running singularity:
 * first try to update singularity to the newest version and reboot your machine,
 * if this does not help, please add `GRUB_CMDLINE_LINUX="max_loop=256"` into `/etc/default/grub` and reboot your machine.
