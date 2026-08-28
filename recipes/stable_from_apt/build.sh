#!/bin/bash

# get the path to this script
THIS_PATH=`dirname "$0"`
REPO_PATH=`( cd "$THIS_PATH/../.." && pwd )`
THIS_PATH=`( cd "$THIS_PATH" && pwd )`
BUILD_ENV=()

is_tmpfs() {
    if command -v findmnt >/dev/null 2>&1; then
        [ "$(findmnt -n -o FSTYPE --target /tmp)" = "tmpfs" ]
    else
        [ "$(stat -f -c %T /tmp 2>/dev/null)" = "tmpfs" ]
    fi
}

# systemd default caps /tmp at half your RAM size, this image unpacks
# an entire linux filesystem => overflows => build fails
# use another directory "tmp" directory instead

if is_tmpfs; then
    echo "[notice] will need sudo permissions to write in /var/tmp/apptainer/tmp"
    DEFAULT_APPTAINER_TMPDIR=/var/tmp/apptainer/tmp
    sudo mkdir -p /var/tmp/apptainer/tmp
    BUILD_ENV=(APPTAINER_TMPDIR=$DEFAULT_APPTAINER_TMPDIR)
fi

sudo env "${BUILD_ENV[@]}" apptainer build $REPO_PATH/images/mrs_uav_system.sif $THIS_PATH/recipe.def
