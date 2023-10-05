#!/bin/bash

set -e

trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

## | ------------------- configure the paths ------------------ |

# Change the following paths when moving the script and the folders around

# get the path to the current directory
MRS_SINGULARITY_PATH=`dirname "$0"`
MRS_SINGULARITY_PATH=`( cd "$MRS_SINGULARITY_PATH" && pwd )`

# alternatively, set it directly
# MRS_SINGULARITY_PATH=$HOME/git/mrs_singularity

# define paths to the subfolders
IMAGES_PATH="$MRS_SINGULARITY_PATH/images"
OVERLAYS_PATH="$MRS_SINGULARITY_PATH/overlays"
MOUNT_PATH="$MRS_SINGULARITY_PATH/mount"

## | ----------------------- user config ---------------------- |

# use <file>.sif for normal container
# use <folder>/ for sandbox container
CONTAINER_NAME="mrs_uav_system.sif"
OVERLAY_NAME="mrs_uav_system.img"

CONTAINED=true  # true: will isolate from the HOST's home
CLEAN_ENV=true # true: will clean the shell environment before runnning container

USE_NVIDIA=false # true: will tell Singularity that it should use nvidia graphics. Does not work every time.

# the following are mutually exclusive
OVERLAY=false  # true: will load persistant overlay (overlay can be created with scripts/create_overlay.sh)
WRITABLE=false # true: will run it as --writable (works with --sandbox containers, image can be converted with scripts/convert_sandbox.sh)

# definy what should be mounted from the host to the container
# [TYPE], [SOURCE (host)], [DESTINATION (container)]
MOUNTS=(
  # mount the custom user workspace into the container
  #                  HOST PATH                                    CONTAINER PATH
  "type=bind" "$MRS_SINGULARITY_PATH/user_ros_workspace" "/home/$USER/user_ros_workspace"

  # mount the MRS shell additions into the container, DO NOT MODIFY
  "type=bind" "$MOUNT_PATH" "/opt/mrs/host"
)

## | ------------------ advanced user config ------------------ |

# not supposed to be changed by a normal user
DEBUG=false           # true: print the singularity command instead of running it
KEEP_ROOT_PRIVS=false # true: let root keep privileges in the container
FAKEROOT=false        # true: run as superuser
DETACH_TMP=true       # true: do NOT mount host's /tmp

## | --------------------- user config end -------------------- |

# check whether we are already in tmux
if [ -n "$TMUX" ]; then
  echo "You are probably in a TMUX session. Exit the tmux session first please."
  exit 1
fi

if [ -z "$1" ]; then
  ACTION="run"
else
  ACTION=${1}
fi

CONTAINER_PATH=$IMAGES_PATH/$CONTAINER_NAME

if $OVERLAY; then

  if [ ! -e $OVERLAYS_PATH/$OVERLAY_NAME ]; then
    echo "Overlay file does not exist, initialize it with the 'create_fs_overlay.sh' script"
    exit 1
  fi

  OVERLAY_ARG="-o $OVERLAYS_PATH/$OVERLAY_NAME"
  $DEBUG && echo "Debug: using overlay"
else
  OVERLAY_ARG=""
fi

if $CONTAINED; then
  CONTAINED_ARG="--home /tmp/singularity/home:/home/$USER"
  $DEBUG && echo "Debug: running as contained"
else
  CONTAINED_ARG=""
fi

if $WRITABLE; then
  WRITABLE_ARG="--writable"
  $DEBUG && echo "Debug: running as writable"
else
  WRITABLE_ARG=""
fi

if $KEEP_ROOT_PRIVS; then
  KEEP_ROOT_PRIVS_ARG="--keep-privs"
  $DEBUG && echo "Debug: keep root privs"
else
  KEEP_ROOT_PRIVS_ARG=""
fi

if $FAKEROOT; then
  FAKE_ROOT_ARG="--fakeroot"
  $DEBUG && echo "Debug: fake root"
else
  FAKE_ROOT_ARG=""
fi

if $CLEAN_ENV; then
  CLEAN_ENV_ARG="-e"
  $DEBUG && echo "Debug: clean env"
else
  CLEAN_ENV_ARG=""
fi

# if we want nvidia, add the "--nv" arg
if $USE_NVIDIA; then
  NVIDIA_ARG="--nv"
else
  NVIDIA_ARG=""
fi

if $DETACH_TMP; then
  TMP_PATH="/tmp/singularity/tmp"
  DETACH_TMP_ARG="--bind $TMP_PATH:/tmp"
  $DEBUG && echo "Debug: detaching tmp from the host"
else
  DETACH_TMP_ARG=""
fi

if $DEBUG; then
  EXEC_CMD="echo"
else
  EXEC_CMD="eval"
fi

MOUNT_ARG=""
if ! $WRITABLE; then

  # prepare the mounting points, resolve the full paths
  for ((i=0; i < ${#MOUNTS[*]}; i++));
  do
    ((i%3==0)) && TYPE[$i/3]="${MOUNTS[$i]}"
    ((i%3==1)) && SOURCE[$i/3]=$( realpath -e "${MOUNTS[$i]}" )
    ((i%3==2)) && DESTINATION[$i/3]=$( realpath -m "${MOUNTS[$i]}" )
  done

  # detect if the installed singularity uses the new --mount commnad
  singularity_help_mount=$( singularity run --help | grep -e "--mount" | wc -l )

  if [ "$singularity_help_mount" -ge "1" ]; then
    for ((i=0; i < ${#TYPE[*]}; i++)); do
      MOUNT_ARG="$MOUNT_ARG --mount ${TYPE[$i]},source=${SOURCE[$i]},destination=${DESTINATION[$i]}"
    done
  else
    for ((i=0; i < ${#TYPE[*]}; i++)); do
      MOUNT_ARG="$MOUNT_ARG --bind ${SOURCE[$i]}:${DESTINATION[$i]}"
    done
  fi

fi

if [[ "$ACTION" == "run" ]]; then
  [ ! -z "$@" ] && shift
  CMD="$@"
elif [[ $ACTION == "exec" ]]; then
  shift
  CMD="/bin/bash -c '${@}'"
elif [[ $ACTION == "shell" ]]; then
  CMD=""
else
  echo "Action is missing"
  exit 1
fi

# create tmp folder for singularity in host's tmp
[ ! -e /tmp/singularity/tmp ] && mkdir -p /tmp/singularity/tmp
[ ! -e /tmp/singularity/home ] && mkdir -p /tmp/singularity/home

# this will set $DISPLAY in the container to the same value as on your host machine
export SINGULARITYENV_DISPLAY=$DISPLAY

$EXEC_CMD singularity $ACTION \
  $NVIDIA_ARG \
  $OVERLAY_ARG \
  $CONTAINED_ARG \
  $WRITABLE_ARG \
  $CLEAN_ENV_ARG \
  $FAKE_ROOT_ARG \
  $KEEP_ROOT_PRIVS_ARG \
  $MOUNT_ARG \
  $DETACH_TMP_ARG \
  $CONTAINER_PATH \
  $CMD
