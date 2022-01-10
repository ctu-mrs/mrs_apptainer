#!/bin/bash

# get the path to this script
REPO_PATH=`dirname "$0"`
REPO_PATH=`( cd "$REPO_PATH/.." && pwd )`

DEBUG=false     # print stuff
OVERLAY=false   # load persistant overlay
DETACH_TMP=true # detach tmp from the host
NVIDIA=false    # use nvidia graphics natively

if $OVERLAY; then
  OVERLAY_ARG="-o $REPO_PATH/overlays/overlay.img"
  $DEBUG && echo "Debug: using overlay"
else
  OVERLAY_ARG=""
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

# create tmp folder for singularity in host's tmp
[ ! -e /tmp/singularity_tmp ] && mkdir -p /tmp/singularity_tmp

$EXEC_CMD singularity exec \
  $NVIDIA_ARG \
  $OVERLAY_ARG \
  $DETACH_TMP_ARG \
  --mount "type=bind,source=$REPO_PATH/mount,destination=/opt/mrs/host" \
  $REPO_PATH/images/mrs_uav_system_extended.sif \
  bash --rcfile "/singularity"
