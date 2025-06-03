#!/bin/bash
#
# generate_pq_certs.sh - Generate PQC certificates (with debugging)
#

source /workspace/scripts/setup/setup_sros2_env.sh

echo "=== Generating PQC Certificates ==="

# Create keystore directory
mkdir -p /workspace/certs
cd /workspace/certs

echo "Creating keystore with ML-DSA44 (Dilithium3)..."
ros2 security create_keystore keystore --pq-algorithm dilithium3

echo "Creating talker enclave..."
ros2 security create_enclave keystore /talker_listener/talker --pq-algorithm dilithium3

echo "Creating listener enclave..."
ros2 security create_enclave keystore /talker_listener/listener --pq-algorithm dilithium3

echo "✓ Certificates generated"

# Debug: Show what was actually created
echo ""
echo "=== Debug: Certificate structure ==="
echo "Contents of /workspace/certs/:"
ls -la /workspace/certs/

echo ""
echo "Contents of keystore:"
ls -la /workspace/certs/keystore/

echo ""
echo "Contents of enclaves:"
ls -la /workspace/certs/keystore/enclaves/ 2>/dev/null || echo "No enclaves directory found"

echo ""
echo "Looking for talker_listener:"
ls -la /workspace/certs/keystore/enclaves/talker_listener/ 2>/dev/null || echo "No talker_listener directory found"

echo ""
echo "Full directory tree:"
find /workspace/certs/ -type d | sort