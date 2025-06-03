#!/bin/bash
set -e

# Install ROS 2 Jazzy from binary packages
apt-get update -qq
apt-get install -y curl lsb-release gnupg2

# Add ROS 2 repository
curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/ros2.list

# Install ROS 2 packages
apt-get update -qq
apt-get install -y \
    ros-jazzy-ros-base \
    ros-jazzy-demo-nodes-cpp \
    ros-jazzy-demo-nodes-py

# Cleanup
apt-get clean
rm -rf /var/lib/apt/lists/*