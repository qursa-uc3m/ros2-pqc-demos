#!/bin/bash
# SROS2 environment setup

# Source ROS 2
if [[ -f "/opt/ros/jazzy/setup.bash" ]]; then
    source /opt/ros/jazzy/setup.bash
elif [[ -f "/usr/local/setup.bash" ]]; then
    source /usr/local/setup.bash
fi

# Source SROS2 workspace
if [[ -f "/opt/ros2_workspace/install/setup.bash" ]]; then
    source /opt/ros2_workspace/install/setup.bash
fi

# Setup OQS OpenSSL
if [[ -d "/opt/oqs_openssl3" ]]; then
    export OPENSSL_ROOT_DIR="/opt/oqs_openssl3"
    export LD_LIBRARY_PATH="/opt/oqs_openssl3/lib64:/opt/oqs_openssl3/lib:$LD_LIBRARY_PATH"
    export PATH="/opt/oqs_openssl3/bin:$PATH"
fi