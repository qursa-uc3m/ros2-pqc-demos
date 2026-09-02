#!/usr/bin/env bash
set -euo pipefail
export NODE_ROLE=talker
source /workspace/scripts/setup/setup_dds_env.sh
exec ros2 run demo_nodes_cpp talker --ros-args --enclave /talker_listener/talker
