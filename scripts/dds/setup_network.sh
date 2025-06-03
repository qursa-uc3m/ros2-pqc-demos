#!/bin/bash
#
# setup_network.sh - Setup network configuration for multi-container DDS
# Copyright (C) 2024 Javier Blanco-Romero
#

source /workspace/scripts/setup/setup_dds_env.sh

# Set node-specific configuration based on role
if [ "$NODE_ROLE" = "talker" ]; then
    export CYCLONEDDS_URI="/workspace/config/cyclonedds/pqc-networked-config.xml"
    echo "Configured as TALKER node"
elif [ "$NODE_ROLE" = "listener" ]; then
    export CYCLONEDDS_URI="/workspace/config/cyclonedds/pqc-listener-config.xml"
    echo "Configured as LISTENER node"
else
    export CYCLONEDDS_URI="/workspace/config/cyclonedds/pqc-networked-config.xml"
    echo "Using default PQC networked configuration"
fi

echo "Network setup complete. DDS will communicate across containers."
echo "Container IP: $(hostname -I)"
echo "Using config: $CYCLONEDDS_URI"
echo "KEM Algorithm: ${KEM_ALGORITHM:-mlkem768}"
echo "Debug Level: ${DEBUG_LEVEL:-INFO}"