#!/bin/bash

# get the path to this script
REPO_PATH=`dirname "$0"`
REPO_PATH=`( cd "$REPO_PATH/.." && pwd )`

ludo singularity build -F $REPO_PATH/images/mrs_uav_system_extended.sif $REPO_PATH/recipes/mrs_uav_system_extended.def