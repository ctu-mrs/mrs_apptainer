#!/bin/bash

# the following section links config files for Tomas's Linux Setup

LINUX_SETUP_LOCATION=/opt/klaxalk/git/linux-setup

if [ -e $LINUX_SETUP_LOCATION ]; then

  # link .vim
  [ ! -e ~/.vim ] && ln -s $LINUX_SETUP_LOCATION/appconfig/vim/dotvim ~/.vim

  [ ! -e ~/.vimrc ] && ln -s $LINUX_SETUP_LOCATION/appconfig/vim/dotvimrc ~/.vimrc

  # link ranger
  [ ! -e ~/.config/ranger ] && mkdir -p ~/.config/ranger

  [ ! -e ~/.config/ranger/rigle.conf ] && ln -s $LINUX_SETUP_LOCATION/appconfig/ranger/rigle.conf ~/.config/ranger/rigle.conf

  [ ! -e ~/.config/ranger/commands.py ] && ln -s $LINUX_SETUP_LOCATION/appconfig/ranger/commands.py ~/.config/ranger/commands.py

  [ ! -e ~/.config/ranger/rc.conf ] && ln -s $LINUX_SETUP_LOCATION/appconfig/ranger/rc.conf ~/.config/ranger/rc.conf

  [ ! -e ~/.config/ranger/scope.sh ] && ln -s $LINUX_SETUP_LOCATION/appconfig/ranger/scope.sh ~/.config/ranger/scope.sh

  # link ycm extra conf
  [ ! -e ~/.ycm_extra_conf.py ] && ln -s $LINUX_SETUP_LOCATION/appconfig/vim/dotycm_extra_conf.py ~/.ycm_extra_conf.py

fi
