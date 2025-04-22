#!/bin/bash

# Exit the script if any command fails
set -e

# the traps make sure the script notifies the use which command has failed
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'echo "$0: \"${last_command}\" command failed with exit code $?"' ERR

# install pkgs needed for cool shell visualizations
apt-get install -y -q \
    toilet \
    dialog

toilet -w 200 -f future "Installing Apptainer"
apt-get update
apt-get install -y software-properties-common
add-apt-repository -y ppa:apptainer/ppa
apt-get update
apt-get install -y apptainer

toilet -w 200 -f future "Testing Apptainer installation"
apptainer exec docker://ghcr.io/apptainer/lolcow cowsay "Apptainer Mooooooo"