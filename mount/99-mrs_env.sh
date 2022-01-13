#!/bin/bash

MRS_LOCATION=/opt/mrs

# link bash and zsh rc files
[ ! -e ~/.bashrc ] &&  ln -s $MRS_LOCATION/host/singularity_bashrc.sh ~/.bashrc
[ ! -e ~/.zshrc ] && ln -s $MRS_LOCATION/host/singularity_zshrc.sh ~/.zshrc
[ ! -e ~/.profile ] && ln -s $MRS_LOCATION/host/singularity_profile.sh ~/.profile

# link .tmux.conf
[ ! -e ~/.tmux.conf ] && [ -e $MRS_LOCATION/mrs_workspace/src/uav_core/installation/dependencies/tmux/dottmux.conf ] && ln -s $MRS_LOCATION/mrs_workspace/src/uav_core/installation/dependencies/tmux/dottmux.conf ~/.tmux.conf

touch ~/.sudo_as_admin_successful

export PS1="[MRS Singularity] ${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "
