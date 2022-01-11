#!/bin/bash

## | -------------------------- paths ------------------------- |

# get the path to this script
REPO_PATH=`dirname "$0"`
REPO_PATH=`( cd "$REPO_PATH/.." && pwd )`

IMAGES_PATH=$REPO_PATH/images

## | ------------------------ paths end ----------------------- |

FROM_SANDBOX=true # set to false to reverse the direction
IMAGE_NAME=testing

## | ------------------- do not modify below ------------------ |

if $FROM_SANDBOX; then
  sudo singularity build --sandbox $IMAGES_PATH/$IMAGE_NAME/ $IMAGES_PATH/$IMAGE_NAME.sif
else
  sudo singularity build $IMAGES_PATH/$IMAGE_NAME.sif $IMAGES_PATH/$IMAGE_NAME/
fi
