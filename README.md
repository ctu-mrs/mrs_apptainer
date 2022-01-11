# mrs_singularity

## How To

1. Install Singularity - [install/install_singularity.sh](./install/install_singularity.sh).
2. Install Docker - [install/install_docker.sh](./install/install_docker.sh).
3. Pull the latest docker image of the MRS UAV System (approx. 4 GB).
```bash
docker pull ctumrs/mrs_uav_system
```
4. Create Singularity image of the MRS UAV System - [scripts/build_mrs_uav_system_from_docker.sh](scripts/build_mrs_uav_system_from_docker.sh). _This can take up to 10 minutes, depending on your computer resources_.
5. Copy the [wrapper_example.sh](./wrapper_example.sh) (versioned example) into `wrapper.sh` (.gitignored). This will allow you to configure the wrapper for yourself.
6. Run the Singularity container using the wrapper [wrapper.sh](./wrapper.sh)
```bash
./wrapper.sh
```

Now you should see the terminal prompt of the singularity image, similar to this:
```bash
[MRS Singularity] user@hostname:~$
```

You can test whether the MRS UAV System is operational by starting the [example simulation session](https://ctu-mrs.github.io/docs/simulation/howto.html).
```bash
[MRS Singularity] user@hostname:~$ cd /opt/mrs/git/simulation/example_tmux_scripts/one_drone_gps
[MRS Singularity] user@hostname:~$ ./start.sh
```

In order to compile your own software with the MRS UAV System dependencies, start by placing it into the `user_ros_workspace/src` folder of this repository.
As an example, clone the [ctu-mrs/example_ros_packages](https://github.com/ctu-mrs/example_ros_packages) and update the submodules using [gitman](https://ctu-mrs.github.io/docs/software/gitman.html):
```bash
cd user_ros_workspace/src
git clone https://github.com/ctu-mrs/example_ros_packages.git
cd example_ros_packages
gitman install
```
This workspace folder is mounted into the container as `~/user_ros_workspace`.
You can then run the singularity image, [init the workspace](https://ctu-mrs.github.io/docs/software/catkin/managing_workspaces/managing_workspaces.html), and build the packages by:
```bash
[MRS Singularity] user@hostname:~$ cd ~/user_ros_workspace/
[MRS Singularity] user@hostname:~$ catkin init
[MRS Singularity] user@hostname:~$ catkin build
```
This should compile your software.
Although the workspace resides on your host computer, the software cannot be run by the host system.
The catkin depencies point to the Container's paths.
In order to run the sofware, go into the singularity container (`./wrapper.sh`) and run it through there.
```bash
./wrapper.sh
[MRS Singularity] user@hostname:~$ cd ~/user_ros_workspace/src/example_ros_packages/tmux_scripts/waypoint_flie
[MRS Singularity] user@hostname:~$ ./start.sh
```

## Default behavior

* The [MRS UAV System](https://github.com/ctu-mrs/mrs_uav_system) is cloned into `/opt/mrs/git/mrs_uav_system`.
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

## Installing additional stuff to existing .sif container

### Bootstraping into a new container

**PROS**:

The preferred way is to bootstrap the existing container into a new contained with a custom recipe file.
This allows you to be independent on the input container and recive updates.

**CONS:**

Building new container takes longer, therefore, finding out what you need to do is tedious.
However, finding what actions you need to can can be done by modifying the container directly, see the maunal down below.

### Modifying existing container

If you really need to add stuff to the container, you can do that by following these steps:

1. convert to _sandbox_ container
```bash
sudo singularity build --sandbox <final-container-directory> <input-file.sif>
```
3. run with **WRITABLE** and **FAKEROOT**
4. modify the container, install stuff, etc.
5. convert back to `.sif`
```bash
sudo singularity build <output-file.sif> <input-container-directory/>
```
