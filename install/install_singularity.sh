#!/bin/bash

SHELL_NAME=$( echo "$SHELL" | grep -Eo '[^/]+/?$' )

RCFILE=~/."$SHELL_NAME"rc

# get the path to this script
MY_PATH=`dirname "$0"`
MY_PATH=`( cd "$MY_PATH" && pwd )`

## | ------------------- configure versions ------------------- |

export SINGULARITY_VERSION=3.10.0
export GO_VERSION=1.18

# export SINGULARITY_VERSION=3.9.5
# export GO_VERSION=1.17

## | ----------------- install pre-requisities ---------------- |

sudo apt-get -y update
sudo apt-get install -y \
    build-essential \
    libssl-dev \
    uuid-dev \
    libgpgme11-dev \
    squashfs-tools \
    libseccomp-dev \
    wget \
    pkg-config \
    git \
    cryptsetup

## | ----------------------- install Go ----------------------- |

INSTALL_GO=true

# check if go is already installed
if [ -e /usr/local/go/bin ]; then

  echo pes

  default=n
  while true; do
    if [[ "$unattended" == "1" ]]
    then
      resp=$default
    else
      read -t 10 -n 2 -p $'\e[1;32mGo is already installed, do you want to re-install it? Doing this might break your pre-existing setup... [y/n] (default: '"$default"$')\e[0m\n' resp || resp=$default
    fi
    response=`echo $resp | sed -r 's/(.*)$/\1=/'`

    if [[ $response =~ ^(y|Y)=$ ]]
    then
      break
    elif [[ $response =~ ^(n|N)=$ ]]
    then
      INSTALL_GO=false
      break
    else
      echo " What? \"$resp\" is not a correct answer. Try y+Enter."
    fi
  done

fi

if $INSTALL_GO; then

  cd /tmp

  export OS=linux
  export ARCH=amd64  # Replace the values as needed
  wget https://dl.google.com/go/go$GO_VERSION.$OS-$ARCH.tar.gz
  sudo tar -C /usr/local -xzvf go$GO_VERSION.$OS-$ARCH.tar.gz
  rm go$GO_VERSION.$OS-$ARCH.tar.gz

  # add $PATH extension to the RC file
  num=`cat $RCFILE | grep -e "PATH.*go" | wc -l`
  if [ "$num" -lt "1" ]; then

    echo '
# add Go to $PATH
export PATH=/usr/local/go/bin:$PATH' >> $RCFILE

    source $RCFILE
  fi

  export PATH="/usr/local/go/bin:$PATH"

fi

## | ------------------- install singularity ------------------ |

cd /tmp

wget https://github.com/sylabs/singularity/releases/download/v${SINGULARITY_VERSION}/singularity-ce-${SINGULARITY_VERSION}.tar.gz
tar -xzf singularity-ce-${SINGULARITY_VERSION}.tar.gz
cd singularity-ce-${SINGULARITY_VERSION}
./mconfig
make -C builddir
sudo make -C builddir install

echo ""
echo "Singularity installed"
