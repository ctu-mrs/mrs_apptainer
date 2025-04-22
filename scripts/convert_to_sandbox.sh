#!/bin/bash

## | -------------------------- paths ------------------------- |

# get the path to this script
REPO_PATH=$(dirname "$0")
REPO_PATH=$(cd "$REPO_PATH/.." && pwd)

IMAGES_PATH=$REPO_PATH/images

## | ------------------------ paths end ----------------------- |

# Check if the first argument ($1) is empty
if [ -z "$1" ]; then
  echo "Error: No input provided. Please specify a value for image name." >&2
  exit 1
fi

IMAGE_NAME=$1

# If $1 is not empty, proceed with the script
echo "Building sandbox with image: $IMAGE_NAME"

## | ------------------- do not modify below ------------------ |
apptainer build --fakeroot --sandbox "$IMAGES_PATH"/$IMAGE_NAME/ $IMAGES_PATH/$IMAGE_NAME.sif
