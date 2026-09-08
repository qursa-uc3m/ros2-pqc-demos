#!/usr/bin/env bash
set -euo pipefail
source /workspace/scripts/setup/setup_sros2_env.sh

export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
export LD_LIBRARY_PATH="/opt/pqsec-dds/adapters/cyclonedds/build:${LD_LIBRARY_PATH:-}"
case "${NODE_ROLE:-talker}" in
  listener) export CYCLONEDDS_URI=/workspace/config/cyclonedds/pqc-listener-config.xml ;;
  talker) export CYCLONEDDS_URI=/workspace/config/cyclonedds/pqc-networked-config.xml ;;
  *) echo "Unsupported NODE_ROLE=${NODE_ROLE}" >&2; return 2 ;;
esac
