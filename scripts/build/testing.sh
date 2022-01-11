#!/bin/bash

# get the path to this script
REPO_PATH=`dirname "$0"`
REPO_PATH=`( cd "$REPO_PATH/.." && pwd )`

sudo singularity build -F $REPO_PATH/images/testing.sif $REPO_PATH/recipes/testing.def
