#!/usr/bin/env bash
set -euo pipefail
source /workspace/scripts/setup/setup_base_env.sh
set +u
source /opt/rmw-zenoh-overlay/install/setup.bash
set -u

export RMW_IMPLEMENTATION=rmw_zenoh_cpp
export LD_LIBRARY_PATH="/opt/zenoh-pqc/lib:${LD_LIBRARY_PATH:-}"
case "${NODE_ROLE:-talker}" in
  talker|listener) export ZENOH_SESSION_CONFIG_URI="/workspace/certs/zenoh-config/${NODE_ROLE}.json5" ;;
  router) export ZENOH_ROUTER_CONFIG_URI=/workspace/certs/zenoh-config/zenohd.json5 ;;
  *) echo "Unsupported NODE_ROLE=${NODE_ROLE}" >&2; return 2 ;;
esac
