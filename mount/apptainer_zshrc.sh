export SHELL=$(which zsh)

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

CONTAINER_ENV_HOST=/opt/env/host

if [ -e $CONTAINER_ENV_HOST/dot_config/dot_zshrc ]; then
  source $CONTAINER_ENV_HOST/dot_config/dot_zshrc
fi

[[ -f /opt/ros/${ROS_DISTRO}/setup.zsh ]] && source /opt/ros/${ROS_DISTRO}/setup.zsh

ros2_jazzy_env() {
  # ROS2 env-varibles
  export ROS_AUTOMATIC_DISCOVERY_RANGE=LOCALHOST
  export ROS_STATIC_PEERS=''
  export RMW_IMPLEMENTATION=rmw_fastrtps_cpp
  export FASTDDS_DEFAULT_PROFILES_FILE=$CONTAINER_ENV_HOST/apptainer_config/ros2/DEFAULT_FASTRTPS_PROFILES_FW.xml

  colcon mixin add mrs file://$CONTAINER_ENV_HOST/apptainer_config/ros2/colcon/index.yaml >/dev/null
  colcon mixin update mrs >/dev/null

  alias clbt='colcon build --packages-up-to $(basename `pwd`)'
  alias clb='colcon build'
  # source the user_workspace, if it exists
  # [ -e ~/user_ros_workspace/install/setup.zsh ] && source ~/user_ros_workspace/install/setup.zsh
  # [ -e ~/user_ros_workspace/src/mrs_ros2_ws/install/setup.zsh ] && source ~/user_ros_workspace/src/mrs_ros2_ws/install/setup.zsh
  [ -e ~/workspaces/mrs_ros2_ws/install/setup.zsh ] && source ~/workspaces/mrs_ros2_ws/install/setup.zsh
}

ros1_noetic_env() {
  alias clbt='catkin bt'
  alias clb='catkin build'
  [ -z "$ROS_PORT" ] && export ROS_PORT=11311
  [ -z "$ROS_MASTER_URI" ] && export ROS_MASTER_URI=http://localhost:$ROS_PORT
  export ROS_WORKSPACES="$ROS_WORKSPACES ~/user_ros_workspace"

  # if host pc is not Ubuntu 20.04
  OS_INFO=$(cat /proc/version)
  if ! ([[ "$OS_INFO" == *"Ubuntu"* ]] && [[ "$OS_INFO" == *"20.04"* ]]); then
    export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
    [[ -f /usr/share/gazebo/setup.bash ]] && source /usr/share/gazebo/setup.bash
  fi

  # source the user_workspace, if it exists
  # [ -e ~/workspaces/indair_ws/devel/setup.zsh ] && source ~/workspaces/indair_ws/devel/setup.zsh
  [ -e ~/workspaces/training_sim_ws/devel/setup.zsh ] && source ~/workspaces/training_sim_ws/devel/setup.zsh
}

if [[ "$ROS_DISTRO" =~ "noetic" ]]; then
  ros1_noetic_env
fi
if [[ "$ROS_DISTRO" =~ "jazzy" ]]; then
  ros2_jazzy_env
fi
echo -e "Sourced ROS-$ROS_DISTRO env"

# prefix the shell prompt with Apptainer
if [[ -f $CONTAINER_ENV_HOST/dot_config/starship.toml ]]; then
  export STARSHIP_CONFIG=$CONTAINER_ENV_HOST/dot_config/starship.toml
  eval "$(starship init zsh)"
else
  PROMPT='[MRS Apptainer]%1~ %# '
fi

# source the linux setup from within
if [ -e /opt/klaxalk/git/linux-setup/appconfig/zsh/dotzshrc ]; then

  source /opt/klaxalk/git/linux-setup/appconfig/zsh/dotzshrc

fi
