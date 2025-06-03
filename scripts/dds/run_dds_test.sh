#!/bin/bash
#
# run_dds_test.sh - Run complete DDS PQC test (single container)
# Copyright (C) 2024 Javier Blanco-Romero
#

source /workspace/scripts/setup/setup_dds_env.sh

echo "=== DDS Security PQC Test ==="
echo "Configuration:"
echo "  CycloneDDS: ${CYCLONEDDS_VERSION:-unknown}"
echo "  KEM Algorithm: ${KEM_ALGORITHM:-mlkem768}"
echo "  Debug Level: ${DEBUG_LEVEL:-INFO}"
echo "  Build Type: ${BUILD_TYPE:-Debug}"
echo ""

# Generate certificates if they don't exist
if [ ! -d "/workspace/certs/keystore" ]; then
    echo "Generating certificates..."
    /workspace/scripts/dds/generate_pq_certs.sh
fi

echo "Starting listener in background..."
/workspace/scripts/dds/run_listener.sh &
LISTENER_PID=$!

# Wait a moment for listener to start
sleep 3

echo "Starting talker..."
timeout 30 /workspace/scripts/dds/run_talker.sh &
TALKER_PID=$!

# Wait for test to complete
wait $TALKER_PID

# Cleanup
kill $LISTENER_PID 2>/dev/null || true

echo "✓ DDS Security PQC test completed"