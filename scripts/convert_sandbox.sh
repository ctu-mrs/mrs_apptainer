#!/bin/bash

# get the path to this script
REPO_PATH=`dirname "$0"`
REPO_PATH=`( cd "$REPO_PATH/.." && pwd )`

# to sandbox
IMAGE_NAME=testing
sudo singularity build --sandbox $REPO_PATH/images/$IMAGE_NAME/ $REPO_PATH/images/$IMAGE_NAME.sif

# # from sandbox
# IMAGE_NAME=testing
# sudo singularity build $REPO_PATH/images/$IMAGE_NAME.sif $REPO_PATH/images/$IMAGE_NAME/
