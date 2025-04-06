# MRS Apptainer

This repository provides a way to run the MRS UAV System in a [Apptainer](https://apptainer.org/) container.
Apptainer allows you, an average user, to use our system without installing it into your system and thus cluttering your OS with our software.
Moreover, the following benefits arise when using Apptainer containers:

* The provided image won't change on its own and, therefore, will work and be compatible even when you update or reinstall your system.
* The provided image will run across Ubuntu versions. You run, e.g., our ROS Noetic-based image on the 18.04 host system.
* The provided image can be backed up easily by copy-and-pasting a single file.
* The provided image can be altered and saved again, allowing you to store our system's particular configuration for later testing.

**Why Apptainer and not just Docker?**

* Apptainer integrates more into the host's system: you will get your user in the container.
* You can get your `$HOME` mounted into the container if needed (NOT on by default).
* With the `$HOME` mounted, the programs running inside the container can use your host's computer config files.
* Running GUI applications is much more straightforward: it just works.

# Prerequisities

MRS Apptainer will run on the following operating systems

* Linux
* Windows 11 with WSL 2.0

## Quick Start Guide (Linux)

1. Install Apptainer - [install/install_apptainer.sh](./install/install_apptainer.sh).
2. Create a Apptainer image of the MRS UAV System. _This should take up to 15 minutes, depending on your internet connection and computer resources_.

| **build script**                                                           | **description**                                                                         |
|----------------------------------------------------------------------------|-----------------------------------------------------------------------------------------|
| [recipes/stable_from_docker/build.sh](recipes/stable_from_docker/build.sh) | installs the latest [Docker Image](https://hub.docker.com/r/ctumrs/mrs_uav_system/tags) |
| [recipes/stable_from_apt/build.sh](recipes/stable_from_apt/build.sh)       | installs directly from the [stable PPA](https://github.com/ctu-mrs/ppa-stable)          |

3. Copy the [example_wrapper.sh](./example_wrapper.sh) (versioned example) into `wrapper.sh` (.gitignored). It will allow you to configure the wrapper for yourself. When copying the `example_wrapper.sh` outside of the `mrs_apptainer` folder, the `MRS_APPTAINER_PATH` variable within the script needs to be pointed to the correct location of the repository.
5. Run the Apptainer container by issuing:
```bash
./wrapper.sh
```

Now, you should see the terminal prompt of the apptainer container, similar to this:
```bash
[MRS Apptainer] user@hostname:~$
```

You can test whether the MRS UAV System is operational by starting the [example Gazebo simulation session](https://ctu-mrs.github.io/docs/simulation/gazebo/gazebo/howto.html).
```bash
[MRS Apptainer] user@hostname:~$ roscd mrs_uav_gazebo_simulation/tmux/one_drone
[MRS Apptainer] user@hostname:~$ ./start.sh
```
5. To compile your software with the MRS UAV System dependencies, start by placing your packages into the `<mrs_apptainer>/user_ros_workspace/src` folder of this repository.
As an example, let's clone the [mrs_core_examples](https://github.com/ctu-mrs/mrs_core_examples).
```bash
cd user_ros_workspace/src
git clone https://github.com/ctu-mrs/mrs_core_examples.git
```
This host's computer folder is mounted into the container as `~/user_ros_workspace`.
You can then run the apptainer container, [init the workspace](https://ctu-mrs.github.io/docs/software/catkin/managing_workspaces/managing_workspaces.html), and build the packages by:
```bash
./wrapper.sh
[MRS Apptainer]$ cd ~/user_ros_workspace/
[MRS Apptainer]$ catkin init
[MRS Apptainer]$ catkin build
```
Although the workspace resides on your host computer, the software cannot be run by the host system.
The container fulfills the dependencies.
To start the software, do so from within the container:
```bash
[MRS Apptainer] user@hostname:~$ cd ~/user_ros_workspace/src/mrs_core_examples/cpp/waypoint_flier/tmux
[MRS Apptainer] user@hostname:~$ ./start.sh
```

## Tailoring the recipes to your needs

Feel free to change the recipe to your needs and  install additional software:

You can select whether you want to bootstrap form a fresh ROS image, or from Tomas's [linux setup](https://github.com/klaxalk/linux-setup) image:
```yaml
From: ros:noetic # uncomment for bootstrapping from ROS Noetic image
# From: klaxalk/linux-setup:master # uncomment for bootstrapping from Tomas's linux-setup
```

You can add additional commands **at the and** of the `%post` section.
For example, add the following code block for installing Visual Studio Code:
```bash
# install visual studio code
# takeon from https://code.visualstudio.com/docs/setup/linux
cd /tmp
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
rm -f packages.microsoft.gpg
```

## Default behavior

* The container is run **without** mounting the host's `$HOME`.
* The container's `/tmp` is mounted into host's `/tmp/apptainer_tmp`.

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

Example of our apptainer wrapper script.
Use this to start our container.
The script contains a _user configuration section_.

### scripts

Shell scripts that automate some of the work with Apptainer.
All the scripts expect to be run from within the _scripts_ folder.

### images

Contains Apptainer images (.gitignored)

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

Place for Apptainer overlay images (.gitignored).

### recipes

Apptainer recipes.
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
`<mrs_apptainer>` stands for the path to where you have cloned this repository.

**BASH**:
```bash
if [ -n "$APPTAINER_NAME" ]; then
  source <mrs_apptainer>/mount/apptainer_bashrc.sh
fi
```

**ZSH**:
```bash
if [ -n "$APPTAINER_NAME" ]; then
  source <mrs_apptainer>/mount/apptainer_zshrc.sh
fi
```

## Installing additional stuff to a container

There are several ways to alter the provided container.

### Creating persistent overlay (preferred)

A persistent overlay is an additional image that is dynamically loaded and _attached_ to the provided container.
Using an overlay is the most straightforward way to store changes to the container, e.g., additional installed software and libraries.

1. Create the overlay image using the provided script: [./scripts/create_overlay.sh](./scripts/create_overlay.sh) (choose the overlay size in the script)
2. Set `OVERLAY=TRUE` inside `wrapper.sh`.
3. Run `sudo ./wrapper` to install additional stuff, e.g.:
```bash
apt-get install git
```
Remember not to put stuff in `$HOME`.

4. Exit the container's terminal and start the wrapper without sudo: `./wrapper.sh`
5. Now, `git` should be installed.

Optinally, the overlay can be embedded into the provided image by running [./scripts/embed_overlay.sh](./scripts/embed_overlay.sh).
Embedding an overlay might be helpful, e.g., when providing the altered image to a third party.

### Bootstrapping into a new container (preferred in later stages)

Although overlays are great, they pose disadvantages: they cannot be versioned, documented, and automated.
That can be overcome by bootstrapping the provided image into a new Apptainer image using a custom Apptainer recipe.

**PROS**:

The preferred way is to bootstrap the existing container into a new container with a custom recipe file.
Creating a customized image allows you to be independent on the input container, receive updates and be compatible with the provided container.

**CONS:**

Building a new container takes longer.
Therefore, finding out what you need to do is tedious.
However, finding what actions you need to take can be done by using an overlay or modifying the container directly.
See the manual down below.

An example recipe, that creates a new image with [Visual Studio Code]() can be found in [./recipes/user_modifications_from_existing_img](./recipes/user_modifications_from_existing_img)
User modifications can also be added directly by modifying one of the main recipes.
However, creating a custom recipe for modifying an already existing image is a more future-proof solution.

### Modifying an existing container (possible but not recommended)

If you need to change the container (even removing files), you can do that by following these steps:

1. convert it to the _sandbox_ container ([./scripts/convert_sandbox.sh](./scripts/convert_sandbox.sh), `TO_SANBOX=true`):
```bash
sudo apptainer build --sandbox <final-container-directory> <input-file.sif>
```
2. modify the path to the container in the `wrapper.sh`:
```bash
CONTAINER_NAME="mrs_uav_system/"
```
3. run the `./wrapper.sh` while setting these variables withing the script: `WRITABLE=true`,
4. modify the container, install stuff, etc.,
5. convert back to `.sif`, ([./scripts/convert_sandbox.sh](./scripts/convert_sandbox.sh), `TO_SANBOX=false`):
```bash
sudo apptainer build <output-file.sif> <input-container-directory/>
```
6. undo the changes in the wrapper, i.e., set `WRITABLE=false` and `CONTAINER_NAME="mrs_uav_system.sif"`.

# Troubleshooting

## General runtime problems

If something is behaving strangly, it might be because your `$HOME` within the container is somehow corrupted.
The first go-to solution is to clean the container's `HOME` and `TMP`.
These folders are located in `/tmp/apptainer` of your machine.
```bash
rm -rf /tmp/apptainer
```

## No loop devices available

If you encounter "**No loop devices available**" problem while running apptainer:
 * first try to update apptainer to the newest version and reboot your machine,
 * if this does not help, please add `GRUB_CMDLINE_LINUX="max_loop=256"` into `/etc/default/grub` and reboot your machine.
