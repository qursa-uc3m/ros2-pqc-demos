#!/usr/bin/env bash
set -euo pipefail

# ROS-generated setup files read optional variables before assigning defaults,
# so they are not safe to source while Bash nounset mode is enabled.
set +u
source "/opt/ros/${ROS_DISTRO:-lyrical}/setup.bash"
if [[ -f /opt/sros2-overlay/install/setup.bash ]]; then
  source /opt/sros2-overlay/install/setup.bash
fi
set -u
