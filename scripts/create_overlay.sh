#!/bin/bash

## | -------------------------- paths ------------------------- |

# get the path to this script
REPO_PATH=`dirname "$0"`
REPO_PATH=`( cd "$REPO_PATH/.." && pwd )`

OVERLAYS_PATH=$REPO_PATH/overlays

## | ------------------------ paths end ----------------------- |

OVERLAY_NAME="overlay"
OVERLAY_SIZE=500 # MB

dd if=/dev/zero of=$OVERLAYS_PATH/$OVERLAY_NAME.img bs=1M count=$OVERLAY_SIZE \
  && mkfs.ext3 -d $OVERLAYS_PATH/$OVERLAY_NAME $OVERLAYS_PATH/$OVERLAY_NAME.img
