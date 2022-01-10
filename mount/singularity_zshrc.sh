export DISPLAY=:0

# create /tmp tmux folder
USER_ID=$( id -u )
[ ! -e "/tmp/tmux-$USER_ID" ] && mkdir -p "/tmp/tmux-$USER_ID"

# link bash and zsh rc files
[ ! -e "$HOME/.bashrc" ] && ln -s /opt/mrs/host/singularity_bashrc.sh $HOME/.bashrc
[ ! -e "$HOME/.zshrc" ] && ln -s /opt/mrs/host/singularity_zshrc.sh $HOME/.zshrc

# link .tmux.conf
[ ! -e "$HOME/.tmux.conf" ] && ln -s /opt/mrs/mrs_workspace/src/uav_core/installation/dependencies/tmux/dottmux.conf $HOME/.tmux.conf

source /opt/ros/noetic/setup.zsh
source /opt/mrs/mrs_workspace/devel/setup.zsh

source /opt/mrs/mrs_workspace/src/uav_core/miscellaneous/shell_additions/shell_additions.sh

echo "singularity RC sourced"
