#!/bin/bash

if [ -z $1 ]; then
  echo "argument required, please supply a command"
  exit 1
fi

# get the path to this script
REPO_PATH=`dirname "$0"`
REPO_PATH=`( cd "$REPO_PATH/.." && pwd )`

CMD="${@}"

singularity exec --nv $REPO_PATH/images/mrs_uav_system_extended.sif bash -c "source /opt/mrs/workspace/devel/setup.bash && export SHELL=/bin/bash && $CMD"
