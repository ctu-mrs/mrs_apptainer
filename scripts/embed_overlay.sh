#!/bin/bash

# get the path to this script
REPO_PATH=`dirname "$0"`
REPO_PATH=`( cd "$REPO_PATH/.." && pwd )`

singularity sif add --datatype 4 --partfs 2 --parttype 4 --partarch 2 --groupid 1 $REPO_PATH/images/mrs_uav_system.sif $REPO_PATH/overlays/overlay.img
