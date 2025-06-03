#!/bin/bash
set -e

# Default values
INSTALL_DIR="/opt/ros2_workspace"
BRANCH="rolling"
BUILD_TYPE="Release"
JOBS=$(nproc)
FORCE_REBUILD=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--prefix) INSTALL_DIR="$2"; shift 2 ;;
        -b|--branch) BRANCH="$2"; shift 2 ;;
        -t|--build-type) BUILD_TYPE="$2"; shift 2 ;;
        -j|--jobs) JOBS="$2"; shift 2 ;;
        -f|--force) FORCE_REBUILD=true; shift ;;
        *) shift ;;
    esac
done

# Source ROS 2 first
if [[ -f "/opt/ros/jazzy/setup.bash" ]]; then
    source /opt/ros/jazzy/setup.bash
elif [[ -f "/usr/local/setup.bash" ]]; then
    source /usr/local/setup.bash
else
    echo "Error: ROS 2 setup.bash not found"
    exit 1
fi

# Check ros2 command
if ! command -v ros2 &> /dev/null; then
    echo "Error: ros2 command not available"
    exit 1
fi

# Install colcon if needed
if ! command -v colcon &> /dev/null; then
    pip3 install --break-system-packages colcon-common-extensions
fi

# Create workspace
mkdir -p "$INSTALL_DIR/src"
cd "$INSTALL_DIR"

# Clean if force rebuild
if [[ "$FORCE_REBUILD" == "true" ]]; then
    rm -rf build/ install/ log/ src/sros2
fi

# Clone SROS2
if [[ ! -d "src/sros2" ]]; then
    git clone --branch "$BRANCH" --depth 1 --single-branch \
        https://github.com/fj-blanco/sros2.git src/sros2
fi

# Install dependencies
pip3 install --break-system-packages \
    cryptography lxml importlib-metadata argcomplete \
    setuptools wheel colcon-common-extensions PyYAML defusedxml

# Build
colcon build --symlink-install --packages-select sros2 \
    --cmake-args -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
    --parallel-workers "$JOBS"

echo "SROS2 build completed successfully"