#!/bin/bash

# get the path to this script
THIS_PATH=$(dirname "$0")
THIS_PATH=$(cd "$THIS_PATH" && pwd)
IMAGES_PATH=$(cd "$THIS_PATH/../../images" && pwd)
IMAGE_NAME="ros1_noetic"

if [[ "$1" =~ "sandbox" ]]; then
    apptainer build --sandbox "$IMAGES_PATH"/"$IMAGE_NAME"/ "$THIS_PATH"/recipe.def
else
    apptainer build --fakeroot --fix-perms "$IMAGES_PATH"/"$IMAGE_NAME".sif "$THIS_PATH"/recipe.def
fi