#!/bin/bash

# get the path to this script
REPO_PATH=`dirname "$0"`
REPO_PATH=`( cd "$REPO_PATH/.." && pwd )`

dd if=/dev/zero of=$REPO_PATH/overlays/overlay.img bs=1M count=500 \
  && mkfs.ext3 -d $REPO_PATH/overlays/overlay $REPO_PATH/overlays/overlay.img
