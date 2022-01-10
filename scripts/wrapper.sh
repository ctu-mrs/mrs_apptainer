#!/bin/bash

## | ---------------------- config start ---------------------- |

DEBUG=false     # print stuff
OVERLAY=false   # load persistant overlay (initialize it with ./create_fs_overlay.sh)
CONTAINED=true  # do not mount host's $HOME
DETACH_TMP=true # do not mount host's /tmp
CLEAN_ENV=true  # clean environment before runnning container
NVIDIA=true     # use nvidia graphics natively

## | ----------------------- config end ----------------------- |

ACTION=${1}

# get the path to this script
REPO_PATH=`dirname "$0"`
REPO_PATH=`( cd "$REPO_PATH/.." && pwd )`

if $OVERLAY; then

  if [ ! -e overlays/overlay.img ]; then
    echo "Overlay file does not exist, initialize it with the 'create_fs_overlay.sh' script"
    exit 1
  fi

  OVERLAY_ARG="-o $REPO_PATH/overlays/overlay.img"
  $DEBUG && echo "Debug: using overlay"
else
  OVERLAY_ARG=""
fi

if $CONTAINED; then
  CONTAINED_ARG="-c"
  $DEBUG && echo "Debug: runing as contained"
else
  CONTAINED_ARG=""
fi

if $CLEAN_ENV; then
  CLEAN_ENV_ARG="-e"
  $DEBUG && echo "Debug: clean env"
else
  CLEAN_ENV_ARG=""
fi

if $NVIDIA; then
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

if [[ "$ACTION" == "run" ]]; then
  CMD=""
elif [[ $ACTION == "exec" ]]; then
  CMD=\""/bin/bash -c source /singularity && ${2}\""
elif [[ $ACTION == "shell" ]]; then
  CMD=""
else
  echo "Action is missing"
  exit 1
fi

# create tmp folder for singularity in host's tmp
[ ! -e /tmp/singularity_tmp ] && mkdir -p /tmp/singularity_tmp

$EXEC_CMD singularity $ACTION \
  $NVIDIA_ARG \
  $OVERLAY_ARG \
  $DETACH_TMP_ARG \
  $CONTAINED_ARG \
  $CLEAN_ENV_ARG \
  --mount "type=bind,source=$REPO_PATH/mount,destination=/opt/mrs/host" \
  $REPO_PATH/images/mrs_uav_system.sif \
  $CMD
