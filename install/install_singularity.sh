PNAME=$( ps -p "$$" -o comm= )
SNAME=$( echo "$SHELL" | grep -Eo '[^/]+/?$' )
if [ "$PNAME" != "$SNAME" ]; then
  exec "$SHELL" -i "$0" "$@"
  exit "$?"
else
  case $- in
    *i*) ;;
    *)
      exec "$SHELL" -i "$0" "$@"
      exit "$?"
      ;;
  esac
  source ~/."$SNAME"rc
fi

RCFILE=~/."$SNAME"rc

# get the path to this script
MY_PATH=`dirname "$0"`
MY_PATH=`( cd "$MY_PATH" && pwd )`

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

cd /tmp

export VERSION=1.17
export OS=linux
export ARCH=amd64  # Replace the values as needed
wget https://dl.google.com/go/go$VERSION.$OS-$ARCH.tar.gz
sudo tar -C /usr/local -xzvf go$VERSION.$OS-$ARCH.tar.gz
rm go$VERSION.$OS-$ARCH.tar.gz

# add $PATH extension to the RC file
num=`cat $RCFILE | grep -e "PATH.*go" | wc -l`
if [ "$num" -lt "1" ]; then

  echo '
# add Go to $PATH
export PATH=/usr/local/go/bin:$PATH' >> $RCFILE

  source $RCFILE
fi

## | ------------------- install singularity ------------------ |

cd /tmp

export VERSION=3.9.2
wget https://github.com/sylabs/singularity/releases/download/v${VERSION}/singularity-ce-${VERSION}.tar.gz
tar -xzf singularity-ce-${VERSION}.tar.gz
cd singularity-ce-${VERSION}
./mconfig
make -C builddir
sudo make -C builddir install

echo ""
echo "Singularity installed"
