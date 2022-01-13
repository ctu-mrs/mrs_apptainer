#!/bin/bash

## | ------------------- configure the paths ------------------ |

# Change these when moving the script and the folders around

# get the path to the repository
REPO_PATH=`dirname "$0"`
REPO_PATH=`( cd "$REPO_PATH" && pwd )`

IMAGES_PATH="$REPO_PATH/images"
OVERLAYS_PATH="$REPO_PATH/overlays"
MOUNT_PATH="$REPO_PATH/mount"

## | ----------------------- user config ---------------------- |

# use <file>.sif for normal container
# use <folder>/ for sandbox container
CONTAINER_NAME="mrs_uav_system.sif"

DEBUG=false # print stuff

CONTAINED=true  # do not mount host's $HOME
DETACH_TMP=true # do not mount host's /tmp
CLEAN_ENV=true  # clean environment before runnning container

# mutually exclusive
OVERLAY=false  # load persistant overlay (initialize it with ./create_fs_overlay.sh)
WRITABLE=false # run as --writable (works with --sandbox containers)

# definy what should be mounted from the host to the container
MOUNTS=(
  # mount the custom user workspace into the container
  "type=bind,source=$REPO_PATH/user_ros_workspace,destination=$HOME/user_ros_workspace"

  # mount the MRS shell additions into the container, DO NOT MODIFY
  "type=bind,source=$MOUNT_PATH,destination=/opt/mrs/host"
)

KEEP_ROOT_PRIVS=false                 # let root keep privileges in the container
FAKEROOT=false                        # run as superuser

## | --------------------- user config end -------------------- |

if [ -z "$1" ]; then
  ACTION="run"
else
  ACTION=${1}
fi

CONTAINER_PATH=$IMAGES_PATH/$CONTAINER_NAME

if $OVERLAY; then

  if [ ! -e $OVERLAYS_PATH/overlay.img ]; then
    echo "Overlay file does not exist, initialize it with the 'create_fs_overlay.sh' script"
    exit 1
  fi

  OVERLAY_ARG="-o $OVERLAYS_PATH/overlay.img"
  $DEBUG && echo "Debug: using overlay"
else
  OVERLAY_ARG=""
fi

if $CONTAINED; then
  CONTAINED_ARG="-c"
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

NVIDIA_COUNT=$( lspci | grep -i -e "vga.*nvidia" | wc -l )

if [ "$NVIDIA_COUNT" -ge "1" ]; then
  NVIDIA_ARG="--nv"
  $DEBUG && echo "Debug: using nvidia"
else
  NVIDIA_ARG=""
fi

if $DETACH_TMP; then
  TMP_PATH="/tmp/singularity_tmp"
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
  for ((i=0; i < ${#MOUNTS[*]}; i++)); do
    MOUNT_ARG="$MOUNT_ARG --mount ${MOUNTS[$i]}"
  done
fi

if [[ "$ACTION" == "run" ]]; then
  shift
  CMD="$@"
elif [[ $ACTION == "exec" ]]; then
  shift
  CMD="/bin/bash -c \"${@}\""
elif [[ $ACTION == "shell" ]]; then
  CMD=""
else
  echo "Action is missing"
  exit 1
fi

# create tmp folder for singularity in host's tmp
[ ! -e /tmp/singularity_tmp ] && mkdir -p /tmp/singularity_tmp

export SINGULARITYENV_DISPLAY=:0

$EXEC_CMD singularity $ACTION \
  $NVIDIA_ARG \
  $OVERLAY_ARG \
  $DETACH_TMP_ARG \
  $CONTAINED_ARG \
  $WRITABLE_ARG \
  $CLEAN_ENV_ARG \
  $FAKE_ROOT_ARG \
  $KEEP_ROOT_PRIVS_ARG \
  $MOUNT_ARG \
  $CONTAINER_PATH \
  $CMD
