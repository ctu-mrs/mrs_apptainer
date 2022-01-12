# get the path to this script
MY_PATH=`dirname "$0"`
MY_PATH=`( cd "$MY_PATH" && pwd )`

cd $MY_PATH

wget https://raw.githubusercontent.com/klaxalk/linux-setup/master/Dockerfile

docker build -t klaxalk/linux-setup:master .

rm Dockerfile
