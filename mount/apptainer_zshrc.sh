export SHELL=$( which zsh )

PROMPT='[MRS Apptainer]%1~ %# '

source /opt/ros/noetic/setup.zsh

# source the user_workspace, if it exists
[ -e ~/user_ros_workspace/devel/setup.zsh ] && source ~/user_ros_workspace/devel/setup.zsh

[ -z "$ROS_PORT" ] && export ROS_PORT=11311
[ -z "$ROS_MASTER_URI" ] && export ROS_MASTER_URI=http://localhost:$ROS_PORT

export ROS_WORKSPACES="$ROS_WORKSPACES ~/user_ros_workspace"

# if host pc is not Ubuntu 20.04
OS_INFO=$(cat /proc/version)
if ! ([[ "$OS_INFO" == *"Ubuntu"* ]] && [[ "$OS_INFO" == *"20.04"* ]]); then
  export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
  source /usr/share/gazebo/setup.bash
fi

# source the linux setup from within
if [ -e /opt/klaxalk/git/linux-setup/appconfig/zsh/dotzshrc ]; then

  source /opt/klaxalk/git/linux-setup/appconfig/zsh/dotzshrc

fi
