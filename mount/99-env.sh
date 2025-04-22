#!/bin/bash

CONTAINER_ENV_HOST=/opt/env/host
# link bash and zsh rc files
[[ -f $CONTAINER_ENV_HOST/apptainer_config/apptainer_bashrc.sh ]] && ln -sf $CONTAINER_ENV_HOST/apptainer_config/apptainer_bashrc.sh ~/.bashrc
[[ -f $CONTAINER_ENV_HOST/apptainer_config/apptainer_zshrc.sh ]] && ln -sf $CONTAINER_ENV_HOST/apptainer_config/apptainer_zshrc.sh ~/.zshrc
[[ -f $CONTAINER_ENV_HOST/apptainer_config/apptainer_profile.sh ]] && ln -sf $CONTAINER_ENV_HOST/apptainer_config/apptainer_profile.sh ~/.profile
[[ -d /opt/oh-my-zsh ]] && ln -sf /opt/oh-my-zsh ~/.oh-my-zsh
# link tmux conf
[[ -d $CONTAINER_ENV_HOST/dot_config/dot_tmux-themepack ]] && ln -sf $CONTAINER_ENV_HOST/dot_config/dot_tmux-themepack ~/.tmux-themepack
[[ -f $CONTAINER_ENV_HOST/dot_config/dot_tmux.conf ]] && ln -sf $CONTAINER_ENV_HOST/dot_config/dot_tmux.conf ~/.tmux.conf

touch ~/.sudo_as_admin_successful
export PS1="[MRS Apptainer] ${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "