#!/bin/bash

# get the path to this script
MY_PATH=`dirname "$0"`
MY_PATH=`( cd "$MY_PATH" && pwd )`

## | ----------------- install pre-requisities ---------------- |

sudo apt-get -y update

sudo apt install -y software-properties-common

sudo add-apt-repository -y ppa:apptainer/ppa

sudo apt-get install -y apptainer-suid
