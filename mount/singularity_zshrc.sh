export SHELL=$( which zsh )

PROMPT='[MRS Singularity]%1~ %# '

source /opt/mrs/mrs_workspace/devel/setup.zsh

# source the user_workspace, if it exists
[ -e ~/user_ros_workspace/devel/setup.zsh ] && source ~/user_ros_workspace/devel/setup.zsh

[ -z "$ROS_PORT" ] && export ROS_PORT=11311
[ -z "$ROS_MASTER_URI" ] && export ROS_MASTER_URI=http://localhost:$ROS_PORT

export PROFILES="COLORSCHEME_DARK"

export ROS_DISTRO="noetic"
export UAV_NAME="uav1"
export NATO_NAME="" # lower-case name of the UAV frame {alpha, bravo, charlie, ...}
export UAV_MASS="3.0" # [kg], used only with real UAV
export RUN_TYPE="simulation" # {simulation, uav}
export UAV_TYPE="f550" # {f550, f450, t650, eagle, naki}
export PROPULSION_TYPE="default" # {default, new_esc, ...}
export ODOMETRY_TYPE="gps" # {gps, optflow, hector, vio, ...}
export INITIAL_DISTURBANCE_X="0.0" # [N], external disturbance in the body frame
export INITIAL_DISTURBANCE_Y="0.0" # [N], external disturbance in the body frame
export STANDALONE="false" # disables the core nodelete manager
export SWAP_GARMINS="false" # swap up/down garmins
export PIXGARM="false" # true if Garmin lidar is connected throught Pixhawk
export SENSORS="" # {garmin_down, garmin_up, rplidar, realsense_front, teraranger, bluefox_optflow, realsense_brick, bluefox_brick}
export WORLD_NAME="simulation" # e.g.: "simulation" <= mrs_general/config/world_simulation.yaml
export MRS_STATUS="readme" # {readme, dynamics, balloon, avoidance, control_error, gripper}
export LOGGER_DEBUG="false" # sets the ros console output level to debug

export ROS_WORKSPACES="$ROS_WORKSPACES /opt/mrs/mrs_workspace ~/user_ros_workspace"

# if host pc is not Ubuntu 20.04
OS_INFO=$(cat /proc/version)
if ! ([[ "$OS_INFO" == *"Ubuntu"* ]] && [[ "$OS_INFO" == *"20.04"* ]]); then
  export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
  source /usr/share/gazebo/setup.bash
fi

# source uav_core from within the container
source /opt/mrs/mrs_workspace/src/uav_core/miscellaneous/shell_additions/shell_additions.sh

# source the linux setup from within
if [ -e /opt/klaxalk/git/linux-setup/appconfig/zsh/dotzshrc ]; then

  source /opt/klaxalk/git/linux-setup/appconfig/zsh/dotzshrc

fi
