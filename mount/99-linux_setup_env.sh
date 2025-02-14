#!/bin/bash

# the following section links config files for Tomas's Linux Setup

MRS_LOCATION=/opt/mrs
LINUX_SETUP_LOCATION=/opt/klaxalk/git/linux-setup

if [ -e $LINUX_SETUP_LOCATION ]; then

  # link .vim
  [ ! -e ~/.vim ] && ln -s $LINUX_SETUP_LOCATION/appconfig/vim/dotvim ~/.vim

  [ ! -e ~/.vimrc ] && ln -s $LINUX_SETUP_LOCATION/appconfig/vim/dotvimrc ~/.vimrc

  # link tmux conf
  [ ! -e ~/.tmux.conf ] && ln -s $LINUX_SETUP_LOCATION/appconfig/tmux/dottmux.conf ~/.tmux.conf

  # link ranger
  [ ! -e ~/.config/ranger ] && mkdir -p ~/.config/ranger

  [ ! -e ~/.config/ranger/rifle.conf ] && ln -s $LINUX_SETUP_LOCATION/appconfig/ranger/rifle.conf ~/.config/ranger/rifle.conf

  [ ! -e ~/.config/ranger/commands.py ] && ln -s $LINUX_SETUP_LOCATION/appconfig/ranger/commands.py ~/.config/ranger/commands.py

  [ ! -e ~/.config/ranger/rc.conf ] && ln -s $LINUX_SETUP_LOCATION/appconfig/ranger/rc.conf ~/.config/ranger/rc.conf

  [ ! -e ~/.config/ranger/scope.sh ] && ln -s $LINUX_SETUP_LOCATION/appconfig/ranger/scope.sh ~/.config/ranger/scope.sh

  [ ! -e ~/.scripts ] && ln -s $LINUX_SETUP_LOCATION/scripts ~/.scripts

  # link ycm extra conf
  [ ! -e ~/.ycm_extra_conf.py ] && ln -s $LINUX_SETUP_LOCATION/appconfig/vim/dotycm_extra_conf.py ~/.ycm_extra_conf.py

  # link .vim.rc additions
  [ ! -e ~/.my.vimrc ] && ln -s $MRS_LOCATION/host/apptainer_vimrc ~/.my.vimrc

fi
