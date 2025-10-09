#!/bin/bash

MRS_LOCATION=/opt/mrs

# link bash and zsh rc files
[ ! -e ~/.bashrc ] &&  ln -s $MRS_LOCATION/host/apptainer_bashrc.sh ~/.bashrc
[ ! -e ~/.profile ] && ln -s $MRS_LOCATION/host/apptainer_profile.sh ~/.profile

touch ~/.sudo_as_admin_successful

export PS1="[MRS Apptainer] ${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "
