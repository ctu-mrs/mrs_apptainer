#!/bin/bash

# Exit the script if any command fails
set -e

# the traps make sure the script notifies the use which command has failed
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

# Change the following paths when moving the script and the folders around
# get the path to the current directory
APPTAINER_PATH=$(dirname "$0")
APPTAINER_PATH=$(cd "$APPTAINER_PATH" && pwd)

# define paths to the subfolders
IMAGES_PATH="$APPTAINER_PATH/images"
RECIPE_PATH="$APPTAINER_PATH/recipes"
OVERLAYS_PATH="$APPTAINER_PATH/overlays"
MOUNT_PATH="$APPTAINER_PATH/mount"
# to store the configuration files from the host (e.g .zshrc, .tmux.conf etc.)
CONTAINER_ENV_HOST="/opt/env/host"
# container $HOME changes depending on the use of --fakeroot or use of --no-home
CONTAINER_HOME=$HOME

# get all the build scripts for the recipes
RECIPES=$(find "$RECIPE_PATH" -name "build.sh")

# generate the list of possible images
IMAGE_OPTIONS=()
declare -A IMAGE_RECIPE_MAP
count=1
for path in $RECIPES; do
  IMAGE_OPTIONS+=($count "$(awk -F= '/^IMAGE_NAME=/ {print $2}' "$path" | tr -d '"')")
  IMAGE_RECIPE_MAP["$(awk -F= '/^IMAGE_NAME=/ {print $2}' "$path" | tr -d '"')"]="$path"
  ((count += 2))
done

# CLI mode to test without dialog
if [[ "$1" =~ "--cli" ]]; then
  if [[ "$2" == "run" || "$2" == "exec" || "$2" == "shell" ]]; then
    ACTION=$2
  else
    echo "Please provide 'run/exec/shell' to execute the Apptainer container" && exit
  fi

  if [ -z "$3" ]; then
    echo "Please provide 'image-name.sif' to use $ACTION in Apptainer" && exit
  else
    CONTAINER_NAME="$3.sif"
  fi
else
  # Display the menu and capture the user's choice
  exec 3>&1
  CHOICE=$(dialog \
    --backtitle "Run Apptainer" \
    --no-tags \
    --title "Images (SIF)" \
    --menu "Choose the image to run" \
    20 40 5 \
    "${IMAGE_OPTIONS[@]}" \
    2>&1 1>&3)
  exec 3>&-

  clear

  exec 3>&1
  MODE_CHOICE=$(dialog \
    --backtitle "Run Apptainer" \
    --no-tags \
    --title "Mode" \
    --menu "Choose the mode to run" \
    10 40 5 \
    1 "WRITABLE" \
    2 "READ-ONLY" \
    2>&1 1>&3)
  exec 3>&-

  # build the image if it does not exist
  if [[ $MODE_CHOICE =~ "2" ]]; then
    CONTAINER_NAME="${IMAGE_OPTIONS[$CHOICE]}.sif"

    if [[ ! -f "$IMAGES_PATH/${IMAGE_OPTIONS[$CHOICE]}.sif" ]]; then
      clear && cd "$(dirname ${IMAGE_RECIPE_MAP[${IMAGE_OPTIONS[$CHOICE]}]})" && source "${IMAGE_RECIPE_MAP[${IMAGE_OPTIONS[$CHOICE]}]}"
    fi
  fi

  if [[ $MODE_CHOICE =~ "1" ]]; then
    CONTAINER_NAME="${IMAGE_OPTIONS[$CHOICE]}/"

    if [[ ! -d "$IMAGES_PATH/${IMAGE_OPTIONS[$CHOICE]}/" ]]; then
      clear && cd "$(dirname "${IMAGE_RECIPE_MAP[${IMAGE_OPTIONS[$CHOICE]}]}")" && source "${IMAGE_RECIPE_MAP[${IMAGE_OPTIONS[$CHOICE]}]}" sandbox
    fi
  fi
fi
clear

# prepare the options for Apptainer

CONTAINED=true   # true: will isolate host $HOME /tmp and /var/tmp
CLEAN_ENV=true   # true: will clean the shell environment before runnning container
USE_NVIDIA=false # true: will tell Apptainer that it should use nvidia graphics. Does not work every time.
# the following are mutually exclusive
OVERLAY=false  # true: will load persistant overlay (overlay can be created with scripts/create_overlay.sh)
WRITABLE=false # true: will run it as --writable (works with --sandbox containers, image can be converted with scripts/convert_sandbox.sh)
FAKEROOT=false # true: emulate root inside the container

if [[ $MODE_CHOICE =~ "1" ]]; then
  WRITABLE=true          # true: will load persistant overlay (overlay can be created with scripts/create_overlay.sh)
  FAKEROOT=true          # true: emulate root inside the container
  CONTAINER_HOME="/root" # $HOME=/root when running with --fakeroot
  CONTAINED=false # false: will isolate only host $HOME and $CWD
fi

# defines what should be mounted from the host to the container
# [TYPE], [SOURCE (host)], [DESTINATION (container)]
# - !!! the folders are not being mounted when running with sudo
MOUNTS=(
  # mount the custom user workspace into the container
  #           HOST PATH                                  CONTAINER PATH
  "type=bind" "$APPTAINER_PATH/workspaces" "$CONTAINER_HOME/workspaces"

  # this dir stCONFIGcustom config only used for the apptainer containers
  "type=bind" "$MOUNT_PATH" "$CONTAINER_ENV_HOST/apptainer_config/"

  # use the shell config of the user inside the container
  "type=bind" "$HOME/.zshrc" "$CONTAINER_ENV_HOST/dot_config/dot_zshrc"
  "type=bind" "$HOME/.tmux-themepack" "$CONTAINER_ENV_HOST/dot_config/dot_tmux-themepack"
  "type=bind" "$HOME/.tmux.conf" "$CONTAINER_ENV_HOST/dot_config/dot_tmux.conf"
  "type=bind" "$HOME/.config/starship.toml" "$CONTAINER_ENV_HOST/dot_config/starship.toml"

  # mount folders to facilitate Xserver piping
  "type=bind" "/tmp/.X11-unix" "/tmp/.X11-unix"
  "type=bind" "/dev/dri" "/dev/dri"
  "type=bind" "$HOME/.Xauthority" "$CONTAINER_HOME/.Xauthority"
)

# not supposed to be changed by a normal user
DEBUG=false           # true: print the apptainer command instead of running it
KEEP_ROOT_PRIVS=false # true: let root keep privileges in the container

# TODO: this must be as an option in the dialog window
ACTION="run"

CONTAINER_PATH=$IMAGES_PATH/$CONTAINER_NAME

if $OVERLAY; then

  if [ ! -e "$OVERLAYS_PATH"/"$OVERLAY_NAME" ]; then
    echo "Overlay file does not exist, initialize it with the 'create_fs_overlay.sh' script"
    exit 1
  fi

  OVERLAY_ARG="-o $OVERLAYS_PATH/$OVERLAY_NAME"
  $DEBUG && echo "Debug: using overlay"
else
  OVERLAY_ARG=""
fi

if $CONTAINED; then
  # mount unique home and tmp to run multiple instances of the same image
  CONTAINED_ARG="--containall"
  $DEBUG && echo "Debug: running as contained"
else
  CONTAINED_ARG="--no-mount home,cwd"
fi

if $WRITABLE; then
  WRITABLE_ARG="--writable"
  $DEBUG && echo "Debug: running as writable"
else
  WRITABLE_ARG=""
fi

if $KEEP_ROOT_PRIVS; then
  KEEP_ROOT_PRIVS_ARG="--keep-privs"
  $DEBUG && echo "Debug: keep root privs"
else
  KEEP_ROOT_PRIVS_ARG=""
fi

if $FAKEROOT; then
  FAKE_ROOT_ARG="--fakeroot"
  $DEBUG && echo "Debug: fake root"
else
  FAKE_ROOT_ARG=""
fi

if $CLEAN_ENV; then
  CLEAN_ENV_ARG="-e"
  $DEBUG && echo "Debug: clean env"
else
  CLEAN_ENV_ARG=""
fi

# if we want nvidia, add the "--nv" arg
if $USE_NVIDIA; then
  NVIDIA_ARG="--nv"
else
  NVIDIA_ARG=""
fi

if $DEBUG; then
  EXEC_CMD="echo"
else
  EXEC_CMD="eval"
fi

# create the directory to mount the host files
# this is not needed in case of a read-only file system image.sif
if $WRITABLE; then
  mkdir -p "$CONTAINER_PATH"/"$CONTAINER_ENV_HOST"/dot_config || exit 1
fi

MOUNT_ARG=""
# prepare the mounting points, resolve the full paths
for ((i = 0; i < ${#MOUNTS[*]}; i++)); do
  ((i % 3 == 0)) && TYPE[$i / 3]="${MOUNTS[$i]}"
  ((i % 3 == 1)) && SOURCE[$i / 3]="${MOUNTS[$i]}"
  ((i % 3 == 2)) && DESTINATION[$i / 3]="${MOUNTS[$i]}"
done

for ((i = 0; i < ${#TYPE[*]}; i++)); do

  if test -e "${SOURCE[$i]}"; then

    FULL_SOURCE=$(realpath -e ${SOURCE[$i]})
    FULL_DESTINATION=$(realpath -m ${DESTINATION[$i]})

    MOUNT_ARG="$MOUNT_ARG --mount ${TYPE[$i]},source=$FULL_SOURCE,destination=$FULL_DESTINATION"

    # create empty files and directories when writable (not needed when the image is not writable)
    if $WRITABLE; then
      if [[ -d "$FULL_SOURCE" ]]; then
        mkdir -p $CONTAINER_PATH$FULL_DESTINATION || exit 1
      fi
      if [[ -f "$FULL_SOURCE" ]]; then
        touch $CONTAINER_PATH$FULL_DESTINATION || exit 1
      fi
    fi

  else
    echo "Error while mounting '${SOURCE[$i]}', the path does not exist".
  fi

done

if [[ "$1" =~ "--cli" && "$ACTION" == "run" ]]; then
  CMD=""
elif [[ $ACTION == "exec" ]]; then
  CMD="/bin/bash -c 'echo "You may pass arguments to the container"'"
else
  CMD=""
fi

# this will set $DISPLAY in the container to the same value as on your host machine
export APPTAINERENV_DISPLAY=$DISPLAY

# add the current user to xhost to use the Xserver
xhost +local:$USER >/dev/null 2>&1

$EXEC_CMD apptainer $ACTION \
  $NVIDIA_ARG \
  $OVERLAY_ARG \
  $CONTAINED_ARG \
  $WRITABLE_ARG \
  $CLEAN_ENV_ARG \
  $FAKE_ROOT_ARG \
  $KEEP_ROOT_PRIVS_ARG \
  $MOUNT_ARG \
  $CONTAINER_PATH \
  $CMD

# remove the current user from xhost to prevent unwanted display access
xhost -local:$USER >/dev/null 2>&1
