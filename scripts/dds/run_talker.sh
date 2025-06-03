#!/bin/bash
#
# run_talker.sh - Run DDS talker with PQC security
# Copyright (C) 2024 Javier Blanco-Romero
#

source /workspace/scripts/setup/setup_dds_env.sh

# Set security environment variables
export ROS_SECURITY_KEYSTORE="/workspace/certs/keystore"
export ROS_SECURITY_ENABLE=true
export ROS_SECURITY_STRATEGY=Enforce

echo "Starting talker with PQC security..."
echo "Using KEM: ${KEM_ALGORITHM:-mlkem768}"
echo "Debug level: ${DEBUG_LEVEL:-INFO}"
echo "Security keystore: $ROS_SECURITY_KEYSTORE"
echo "Security enabled: $ROS_SECURITY_ENABLE"
echo "Config: $CYCLONEDDS_URI"

ros2 run demo_nodes_cpp talker --ros-args --enclave /talker_listener/talker