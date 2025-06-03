#!/bin/bash
#
# setup_dds_env.sh - DDS-specific environment setup
# Copyright (C) 2024 Javier Blanco-Romero
#

# Source base environment first
source /workspace/scripts/setup/setup_base_env.sh

echo "=== Setting up DDS Environment ==="

# Step 1: Set up CycloneDDS environment
echo "1. Setting up CycloneDDS..."
export LD_LIBRARY_PATH="/opt/cyclonedds/lib:$LD_LIBRARY_PATH"
export PATH="/opt/cyclonedds/bin:$PATH"
export PKG_CONFIG_PATH="/opt/cyclonedds/lib/pkgconfig:$PKG_CONFIG_PATH"
echo "✓ CycloneDDS configured"

# Step 2: Set up PQSec-DDS plugin
echo "2. Setting up PQSec-DDS plugin..."
export LD_LIBRARY_PATH="/workspace/pqsec-dds/src/build/lib:$LD_LIBRARY_PATH"
echo "✓ PQSec-DDS plugin configured"

# Step 3: Set default CycloneDDS configuration
echo "3. Setting CycloneDDS configuration..."
if [ -n "$NODE_ROLE" ]; then
    if [ "$NODE_ROLE" = "talker" ]; then
        export CYCLONEDDS_URI="/workspace/config/cyclonedds/pqc-networked-config.xml"
        echo "✓ Configured as TALKER node"
    elif [ "$NODE_ROLE" = "listener" ]; then
        export CYCLONEDDS_URI="/workspace/config/cyclonedds/pqc-listener-config.xml"
        echo "✓ Configured as LISTENER node"
    fi
else
    export CYCLONEDDS_URI="/workspace/config/cyclonedds/pqc-networked-config.xml"
    echo "✓ Using default PQC networked configuration"
fi

# Step 4: Display configuration information
echo ""
echo "=== DDS Environment Ready ==="
echo "CycloneDDS version: ${CYCLONEDDS_VERSION:-unknown}"
echo "KEM Algorithm: ${KEM_ALGORITHM:-mlkem768}"
echo "Debug Level: ${DEBUG_LEVEL:-INFO}"
echo "Build Type: ${BUILD_TYPE:-Debug}"
echo "Config file: $CYCLONEDDS_URI"
echo "Plugin library: /workspace/pqsec-dds/src/build/lib/libdds_pqsec.so"
echo ""