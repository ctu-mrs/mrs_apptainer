#!/bin/bash

# get the path to this script
THIS_PATH=`dirname "$0"`
REPO_PATH=`( cd "$THIS_PATH/../.." && pwd )`
THIS_PATH=`( cd "$THIS_PATH" && pwd )`

singularity build --fakeroot --fix-perms -F $REPO_PATH/images/testing.sif $THIS_PATH/testing.def
