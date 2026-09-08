#!/usr/bin/env bash
set -euo pipefail
source /workspace/scripts/setup/setup_base_env.sh

export ROS_SECURITY_KEYSTORE=${ROS_SECURITY_KEYSTORE:-/workspace/certs/keystore}
export ROS_SECURITY_ENABLE=${ROS_SECURITY_ENABLE:-true}
export ROS_SECURITY_STRATEGY=${ROS_SECURITY_STRATEGY:-Enforce}
