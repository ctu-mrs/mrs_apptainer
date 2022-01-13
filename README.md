# MRS Singularity

## How to start

1. Install Singularity - [install/install_singularity.sh](./install/install_singularity.sh).
2. (optional) Install Docker - [install/install_docker.sh](./install/install_docker.sh).
3. Create Singularity image of the MRS UAV System. _This can take up to 30 minutes, depending on your internet connection and computer resources_. This will download approx. 5 GB of data from the internet.

| **build script**                                                                                                 | **contains**                                                                                                                                                                |
|------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [recipes/01_minimal/build.sh](recipes/01_minimal/build.sh)                                           | [MRS UAV System](https://github.com/ctu-mrs/mrs_uav_system)                                                                                                                 |
| [recipes/02_with_linux_setup/build.sh](recipes/02_with_linux_setup/build.sh)                         | [MRS UAV System](https://github.com/ctu-mrs/mrs_uav_system) + [linux-setup](https://github.com/klaxalk/linux-setup)                                                         |
| [recipes/03_with_uav_modules/build.sh](recipes/03_with_uav_modules/build.sh)                         | [MRS UAV System](https://github.com/ctu-mrs/mrs_uav_system) + [UAV Modules](https://github.com/ctu-mrs/uav_modules)                                                         |
| [recipes/04_with_linux_setup_uav_modules/build.sh](recipes/04_with_linux_setup_uav_modules/build.sh) | [MRS UAV System](https://github.com/ctu-mrs/mrs_uav_system) + [linux-setup](https://github.com/klaxalk/linux-setup) + [UAV Modules](https://github.com/ctu-mrs/uav_modules) |

4. Copy the [wrapper_example.sh](./wrapper_example.sh) (versioned example) into `wrapper.sh` (.gitignored). This will allow you to configure the wrapper for yourself.
5. Run the Singularity container using the [wrapper.sh](./wrapper.sh) as
```bash
./wrapper.sh
```

Now, you should see the terminal prompt of the singularity image, similar to this:
```bash
[MRS Singularity] user@hostname:~$
```

You can test whether the MRS UAV System is operational by starting the [example simulation session](https://ctu-mrs.github.io/docs/simulation/howto.html).
```bash
[MRS Singularity] user@hostname:~$ cd /opt/mrs/git/simulation/example_tmux_scripts/one_drone_gps
[MRS Singularity] user@hostname:~$ ./start.sh
```

In order to compile your own software with the MRS UAV System dependencies, start by placing your packages into the `user_ros_workspace/src` folder of this repository.
As an example, let's clone the [ctu-mrs/example_ros_packages](https://github.com/ctu-mrs/example_ros_packages) and update the submodules using [gitman](https://ctu-mrs.github.io/docs/software/gitman.html):
```bash
cd user_ros_workspace/src
git clone https://github.com/ctu-mrs/example_ros_packages.git
```
This host's computer folder is mounted into the container as `~/user_ros_workspace`.
You can then run the singularity image, [init the workspace](https://ctu-mrs.github.io/docs/software/catkin/managing_workspaces/managing_workspaces.html), and build the packages by:
```bash
[MRS Singularity] user@hostname:~$ cd ~/user_ros_workspace/
[MRS Singularity] user@hostname:~$ gitman install
[MRS Singularity] user@hostname:~$ catkin init
[MRS Singularity] user@hostname:~$ catkin build
```
This should compile your software.
Although the workspace resides on your host computer, the software cannot be run by the host system.
The dependencies are fullfilled by the container.
In order to run the sofware, go into the singularity container (`./wrapper.sh`) and run the software through there.
```bash
./wrapper.sh
[MRS Singularity] user@hostname:~$ cd ~/user_ros_workspace/src/example_ros_packages/tmux_scripts/waypoint_flie
[MRS Singularity] user@hostname:~$ ./start.sh
```

## Default behavior

* The [MRS UAV System](https://github.com/ctu-mrs/mrs_uav_system) is cloned into `/opt/mrs/git`.
* The **mrs_workspace** is located in `/opt/mrs/mrs_workspace`.
* The container is run **without** mounted the host's `$HOME`.
* The container's `/tmp` is mounted into host's `/tmp/singularity_tmp`.

## Repository structure

```
.
├── docker
├── images
├── install
├── mount
├── overlays
├── README.md
├── recipes
├── scripts
├── user_ros_workspace
└── wrapper.sh
```

### wrapper.sh

The main Singularity wrapper script.
Use this to start our image.
The script contains a _user configuration section_, please.

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
The packages need to be placed directle into `user_ros_workspace/src` without linking, the links do not translate into the container.
The contents of the `user_ros_workspace` folder are .gitignored.

### mount

Folder with MRS scripts and shell additions, that is mounted dynamically into the container as `/opt/mrs/host`.
The folder contains the `.bashrc`, `.profile` and `.zshrc` that are sourced within the container when running it without host's `$HOME`.
You can modify these to change the ROS behavior.

### ovelays

Place for Singularity overlay images (.gitignored).

### recipes

Singularity recipes.

### docker

Build script for the MRS UAV System docker image.

## Mounting host's $HOME

By default, the host's $HOME directory is not mounted.
In order to mount the host's $HOME into the container, run the `./wrapper.sh` with `CONTAINED=false`.
However, this will make the container's shells to source your own shell RC file.
In order to make the container run with the internal ROS environment, put the following code snippet into your `.bashrc` and/or `.zshrc`.
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

## Installing additional stuff to existing .sif container

### Bootstraping into a new container

**PROS**:

The preferred way is to bootstrap the existing container into a new contained with a custom recipe file.
This allows you to be independent on the input container and recive updates.

**CONS:**

Building new container takes longer, therefore, finding out what you need to do is tedious.
However, finding what actions you need to can can be done by modifying the container directly, see the maunal down below.

### Modifying an existing container

If you really need to add stuff to the container, you can do that by following these steps:

1. convert to _sandbox_ container
```bash
sudo singularity build --sandbox <final-container-directory> <input-file.sif>
```
3. run `./wrapper.sh` with `WRITABLE=true` and `FAKEROOT=true`,
4. modify the container, install stuff, etc.,
5. convert back to `.sif`,
```bash
sudo singularity build <output-file.sif> <input-container-directory/>
```
