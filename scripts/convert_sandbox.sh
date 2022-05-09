#!/bin/bash

## | -------------------------- paths ------------------------- |

# get the path to this script
REPO_PATH=`dirname "$0"`
REPO_PATH=`( cd "$REPO_PATH/.." && pwd )`

IMAGES_PATH=$REPO_PATH/images

## | ------------------------ paths end ----------------------- |

TO_SANDBOX=true # set to false to reverse the direction
IMAGE_NAME=mrs_uav_system

## | ------------------- do not modify below ------------------ |

if $TO_SANDBOX; then
  echo "building --sandbox image"
  singularity build --fakeroot --sandbox $IMAGES_PATH/$IMAGE_NAME/ $IMAGES_PATH/$IMAGE_NAME.sif
else
  singularity build --fakeroot $IMAGES_PATH/$IMAGE_NAME.sif $IMAGES_PATH/$IMAGE_NAME/
fi
