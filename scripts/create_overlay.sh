#!/bin/bash

## | -------------------------- paths ------------------------- |

# get the path to this script
REPO_PATH=`dirname "$0"`
REPO_PATH=`( cd "$REPO_PATH/.." && pwd )`

OVERLAYS_PATH=$REPO_PATH/overlays

## | ------------------------ paths end ----------------------- |

OVERLAY_NAME="mrs_uav_system.img"
OVERLAY_SIZE=500 # MB

# create the template for overlay file system
TEMPLATE_PATH=$( mktemp -d )
mkdir -p $TEMPLATE_PATH/upper
mkdir -p $TEMPLATE_PATH/work

dd if=/dev/zero of=$OVERLAYS_PATH/$OVERLAY_NAME bs=1M count=$OVERLAY_SIZE \
  && mkfs.ext3 -d $TEMPLATE_PATH $OVERLAYS_PATH/$OVERLAY_NAME
