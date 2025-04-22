# MRS Apptainer

This repository provides a way to run the different software systems inside a [Apptainer](https://apptainer.org/) container.
Apptainer allows you, an average user, to use software systems like the [MRS-UAV System](https://github.com/ctu-mrs/mrs_uav_system) without installing it into your local system and thus cluttering your OS with different software.

**Advantages of using Apptainer for development**

* The container image won't change on its own and, therefore, will work and be compatible even when you update or reinstall your system.
* The container image will run across different OS versions, e.g., with a ROS Noetic-based image on the 18.04 host system.
* The container image can be backed up easily by copy-pasting a single file.
* The container image (sandboxed) can be altered and saved again, allowing you to store a particular configuration for later testing.

**Why Apptainer and not just Docker?**

| Feature                | Docker                                | Apptainer                          |
|------------------------|---------------------------------------|------------------------------------|
| Privileges Required    | Root/Sudo                             | User-level (no root needed)        |
| Security Model         | Isolated, but root access risk        | User-bound, safer                  |
| Image Format           | Layered filesystem                    | Single file image                  |
| Host Integration       | Strong isolation                      | Direct host integration            |
| Docker Image Support   | Native                                | Can import and run Docker images   |
| File system access     | Isolated and hard to manage           | Easy to manage                     |
| GUI applications       | Very difficult to run                 | Works out of the box               |

## Installation

MRS Apptainer will run on the following operating systems

### Linux (Ubuntu)

* Install Apptainer - [install/install_apptainer.sh](./install/install_apptainer.sh).

### Windows 11 with WSL 2.0

TODO

## Using MRS Apptainer

| **images**                                                           | **description**                                                                         |
|----------------------------------------------------------------------------|-----------------------------------------------------------------------------------------|
| mrs_system_docker | Installs the latest [MRS System Docker Image](https://hub.docker.com/r/ctumrs/mrs_uav_system/tags) |
| mrs_system_apt    | Installs directly from the [MRS System stable PPA](https://github.com/ctu-mrs/ppa-stable)          |
| ros1_noetic       | Installs bare-bones ROS-noetic with some utilities                                                 |
| ros2_jazzy        | Installs bare-bones ROS-jazzy with some utilities                                                  |

### READ-ONLY mode

* In this mode, the container image can not be modified which means that programs like `apt` will fail as they modify the root file system.
* The user can modify anything inside the `workspaces` directory mounted from the user's system.
![Demo](.media/demo-read-only.gif)

### WRITABLE mode

* In this mode, the container image is actually a directory which can be modified by the user inside the container.
* The changes made inside the container **persists** outside and in the next run of the container.
* This mode is particularly useful when you need to install software to work with the packages inside the `workspaces` directory.
* The user can still modify the `workspaces` directory which is mounted separately.
![Demo](.media/demo-writable.gif)

## Examples

### Testing the MRS-UAV System

* Run the container using the image `mrs_system_apt` in either `READ-ONLY` or `WRITABLE` mode as shown above.
* Navigate to the MRS system gazebo example

```bash
roscd mrs_uav_gazebo_simulation/tmux/one_drone
```

* Run the MRS simulation example

```bash
./start.sh
```

## Advanced development

### Repository structure

```
.
├── images
├── install
├── mount
├── recipes
├── scripts
├── workspaces
├── run_container.sh
└── README.md
```

<details>
<summary>>>> Click to expand <<<</summary>

#### run_container.sh

* Prepares the images from the recipe files.
* Creates the mount points and prepares the necessary flags for the `apptainer` command.

#### images

* Contains the images and sandboxes created by the `run_container.sh`.
* The contents of this directory are .gitignored

#### install

* Contains the install script to download, install and test Apptainer.

#### mount

* This directory is mounted inside `/opt/env/host/apptainer_config`.
* It contains the configuration files for setting up the shell when the container starts, for e.g. `.bashrc`, `.profile`, and `.zshrc`

#### recipes

* Contains the definition and build files for creating Apptainer images and sandboxes.

#### scripts

* Contains utility scripts.

#### workspaces

* This directory is always mounted inside the container and all the content inside the directory can be modified from the container.
* It can be used to store third-party software packages and ROS packages which will be compiled and build from inside the container.
* Do not use symlinks inside this directory as they can not be resolved from the container.
* The contents of this directory are .gitignored.

</details>

### Making a new recipe

You can create your personal recipe, defining the software that should exist in the container and the behavior of the container itself.

* Create a new folder `my_recipe` inside the `recipes` folder.
* Copy your Apptainer definition file inside `my_recipe` as `recipe.def` or use the following example below.
* Copy the `build.sh` from another recipe and rename the `IMAGE_NAME` for the `run_apptaine.sh` script to find your recipe.

```yaml
# Source of the image
Bootstrap: docker
From: ros:noetic

# You can add additional commands **at the and** of the `%post` section.
%post
  apt-get -y update

  # directory to store env config files
  export CONTAINER_ENV_HOST=/opt/env/host
  mkdir -p $CONTAINER_ENV_HOST

  # link the env file (will be mounted at runtime) to the default env file
  # file in /.singularity.d/env/99-env.sh are sourced at startup
  ln -s $CONTAINER_ENV_HOST/apptainer_config/99-env.sh /.singularity.d/env/99-env.sh

  # ONLY MODIFY AFTER THIS

  # install visual studio code
  # takeon from https://code.visualstudio.com/docs/setup/linux
  cd /tmp
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
  install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
  sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
  rm -f packages.microsoft.gpg

%environment
  export LANG=en_US.UTF-8

%runscript
  CMD="${@}"

  if [ -z "${CMD}" ]; then
    /bin/zsh --login
  else
    /bin/zsh --login -c "${CMD}"
  fi

  exit 0
```

### Default flags

| Flag | true | false |
|------|------|-------|
| CONTAINED | Isolate the $HOME, /tmp, /var/tmp, $CWD of host | Isolate only $HOME and $CWD of host |
| CLEAN_ENV | Container has no env variables from the parent shell | Container has env variables from the parent shell |
| USE_NVIDIA | Container has access to the Nvidia graphic drivers (if available) | Not using Nvidia graphics |
| WRITABLE | Provide read/write access to the entire container | Only read access to the container (other than the `workspaces`)|
| FAKEROOT | Emulate `root` user inside the container (for `apt install` etc.) | Only have `$USER` level access inside the container |

### Mounting inside the container

| HOST PATH                                   | CONTAINER PATH                                 | Notes                                                      |
|----------------------------------------------|------------------------------------------------|------------------------------------------------------------|
| $APPTAINER_PATH/workspaces                   | $CONTAINER_HOME/workspaces                     | Contains all the software development packages                                                            |
| $MOUNT_PATH                                  | $CONTAINER_ENV_HOST/apptainer_config/          | Custom config only used for Apptainer containers           |
| $HOME/.zshrc                                 | $CONTAINER_ENV_HOST/dot_config/dot_zshrc       | Use the shell config of the user inside the container      |
| $HOME/.tmux-themepack                        | $CONTAINER_ENV_HOST/dot_config/dot_tmux-themepack | Use the tmux theme of the user inside the container   |
| $HOME/.tmux.conf                             | $CONTAINER_ENV_HOST/dot_config/dot_tmux.conf   | Use the tmux config of the user inside the container      |
| $HOME/.config/starship.toml                  | $CONTAINER_ENV_HOST/dot_config/starship.toml   | Use the starship config of the user inside the container      |
| /tmp/.X11-unix                               | /tmp/.X11-unix                                 | Facilitate Xserver connection |
| /dev/dri                                     | /dev/dri                                       | Facilitate Xserver piping                                  |
| $HOME/.Xauthority                            | $CONTAINER_HOME/.Xauthority                    | Facilitate Xserver piping                                  |

* You can add an addition mounting option by adding the following line to the `MOUNTS` list inside `run_apptainer.sh`.

```bash
"type=bind" "<absolute-path-in-host>" "<absolute-path-inside-container>"
```

## Troubleshooting

**No loop devices available**

If you encounter "**No loop devices available**" problem while running apptainer:

* first try to update apptainer to the newest version and reboot your machine,
* if this does not help, please add `GRUB_CMDLINE_LINUX="max_loop=256"` into `/etc/default/grub` and reboot your machine.
