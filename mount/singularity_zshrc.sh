export DISPLAY=:0

PROMPT='[MRS Singularity]%1~ %# '

[ -e /opt/ros/noetic/setup.zsh ] && source /opt/ros/noetic/setup.zsh
[ -e /opt/mrs/mrs_workspace/devel/setup.zsh ] && source /opt/mrs/mrs_workspace/devel/setup.zsh

[ -e /opt/mrs/mrs_workspace/src/uav_core/miscellaneous/shell_additions/shell_additions.sh ] && \
  source /opt/mrs/mrs_workspace/src/uav_core/miscellaneous/shell_additions/shell_additions.sh

echo "singularity ZSH RC sourced"
