#!/bin/bash
#
# setup_base_env.sh - Base environment setup for all PQC demos
# Copyright (C) 2024 Javier Blanco-Romero
#

echo "=== Setting up Base PQC Environment ==="

# Step 1: Set up OQS environment
echo "1. Setting up OQS environment..."
if [ -f "/opt/oqs_openssl3/setup_env.sh" ]; then
    source /opt/oqs_openssl3/setup_env.sh
else
    export OPENSSL_ROOT_DIR="/opt/oqs_openssl3/.local"
    export OPENSSL_CONF="/opt/oqs_openssl3/.local/ssl/openssl.cnf"
    export OPENSSL_MODULES="/opt/oqs_openssl3/.local/lib64/ossl-modules"
    export LD_LIBRARY_PATH="/opt/oqs_openssl3/.local/lib64:$LD_LIBRARY_PATH"
    export OQS_PROVIDER_NAME="oqsprovider"
    export OQS_PROVIDER_PATH="/opt/oqs_openssl3"
    echo "✓ OQS environment configured"
fi

# Step 2: Set up ROS 2
echo "2. Setting up ROS 2..."
source /opt/ros/jazzy/setup.bash
echo "✓ ROS 2 Jazzy sourced"

# Step 3: Set up SROS2 environment
echo "3. Setting up SROS2..."
export ROS_SECURITY_KEYSTORE="/workspace/certs/keystore"
export ROS_SECURITY_ENABLE="true"
export ROS_SECURITY_STRATEGY="Enforce"
export PQ_DEBUG_LEVEL="${DEBUG_LEVEL:-INFO}"
echo "✓ SROS2 configured"

# Step 4: Common paths
export PATH="/opt/oqs_openssl3/.local/bin:$PATH"
export PKG_CONFIG_PATH="/opt/oqs_openssl3/.local/lib64/pkgconfig:$PKG_CONFIG_PATH"

echo ""
echo "=== Base Environment Ready ==="
echo "Available tools:"
echo "  - ROS 2 Jazzy"
echo "  - OpenSSL with OQS provider"
echo "  - Enhanced SROS2 with PQC support"
echo "  - Demo nodes (cpp/python)"
echo ""
echo "Next: Source middleware-specific environment"