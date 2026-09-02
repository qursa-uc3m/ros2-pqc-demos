#!/usr/bin/env bash
set -euo pipefail

source "/opt/ros/${ROS_DISTRO:-lyrical}/setup.bash"
if [[ -f /opt/sros2-overlay/install/setup.bash ]]; then
  source /opt/sros2-overlay/install/setup.bash
fi

export ROS_SECURITY_KEYSTORE=${ROS_SECURITY_KEYSTORE:-/workspace/certs/keystore}
export ROS_SECURITY_ENABLE=${ROS_SECURITY_ENABLE:-true}
export ROS_SECURITY_STRATEGY=${ROS_SECURITY_STRATEGY:-Enforce}
