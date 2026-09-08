#!/usr/bin/env bash
set -euo pipefail
source /workspace/scripts/setup/setup_base_env.sh

export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
export LD_LIBRARY_PATH="/opt/pqsec-dds/adapters/cyclonedds/build:/opt/cyclonedds-pqc/lib:${LD_LIBRARY_PATH:-}"
# rmw_cyclonedds injects the stock DDS Security plugin names when ROS security
# is enabled. This demo configures DDS Security directly below so that the
# experimental authentication plugin is not silently replaced.
export ROS_SECURITY_ENABLE=false
case "${NODE_ROLE:-talker}" in
  listener) export CYCLONEDDS_URI=/workspace/config/cyclonedds/pqc-listener-config.xml ;;
  talker) export CYCLONEDDS_URI=/workspace/config/cyclonedds/pqc-networked-config.xml ;;
  *) echo "Unsupported NODE_ROLE=${NODE_ROLE}" >&2; return 2 ;;
esac
