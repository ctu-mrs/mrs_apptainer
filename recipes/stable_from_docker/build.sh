#!/bin/bash

# get the path to this script
THIS_PATH=`dirname "$0"`
REPO_PATH=`( cd "$THIS_PATH/../.." && pwd )`
THIS_PATH=`( cd "$THIS_PATH" && pwd )`
APPTAINER_TMPDIR=/var/tmp/apptainer/tmp

# systemd default caps /tmp at half your RAM size, this image unpacks
# an entire linux filesystem => overflows => build fails
# use a temporary directory that lives on disk instead

sudo mkdir -p "${APPTAINER_TMPDIR}"
sudo env APPTAINER_TMPDIR="${APPTAINER_TMPDIR}" apptainer build $REPO_PATH/images/mrs_uav_system.sif $THIS_PATH/recipe.def
