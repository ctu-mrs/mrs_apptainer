#!/bin/bash

CMD="${@}"

singularity exec --nv mrs.sif bash -c "source /opt/mrs/workspace/devel/setup.bash && export SHELL=/bin/bash && $CMD" 
