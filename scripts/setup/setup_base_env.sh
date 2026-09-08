#!/usr/bin/env bash
set -euo pipefail

source "/opt/ros/${ROS_DISTRO:-lyrical}/setup.bash"
if [[ -f /opt/sros2-overlay/install/setup.bash ]]; then
  source /opt/sros2-overlay/install/setup.bash
fi
