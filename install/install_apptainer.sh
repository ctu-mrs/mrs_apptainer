#!/bin/bash

sudo apt-get -y update

sudo apt -y install software-properties-common

sudo add-apt-repository -y ppa:apptainer/ppa

sudo apt-get -y install apptainer-suid
