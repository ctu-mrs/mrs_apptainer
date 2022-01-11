# get the path to this script
MY_PATH=`dirname "$0"`
MY_PATH=`( cd "$MY_PATH" && pwd )`

cd $MY_PATH

wget https://raw.githubusercontent.com/ctu-mrs/mrs_uav_system/master/Dockerfile

docker build -t ctumrs/mrs_uav_system:latest .
