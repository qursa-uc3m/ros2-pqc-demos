#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 6 ]]; then
  echo "usage: $0 ZENOH_COMMIT ZENOHC_COMMIT ZENOHCXX_COMMIT RMW_ZENOH_REF PREFIX OVERLAY" >&2
  exit 2
fi

zenoh_commit=$1
zenohc_commit=$2
zenohcxx_commit=$3
rmw_zenoh_ref=$4
prefix=$5
overlay=$6
source_root=/opt/src
zenoh_source=${source_root}/zenoh
zenohc_source=${source_root}/zenoh-c
zenohcxx_source=${source_root}/zenoh-cpp
rmw_source=${source_root}/rmw_zenoh

mkdir -p "${source_root}" "${prefix}" "${overlay}"

git clone https://github.com/eclipse-zenoh/zenoh.git "${zenoh_source}"
git -C "${zenoh_source}" checkout --detach "${zenoh_commit}"
git -C "${zenoh_source}" apply /opt/patches/zenoh-rustls-aws-lc-pqc.patch

git clone https://github.com/eclipse-zenoh/zenoh-c.git "${zenohc_source}"
git -C "${zenohc_source}" checkout --detach "${zenohc_commit}"

# zenoh-c pins the same Zenoh Git revision in its generated Cargo input. Point
# every such dependency at the locally patched Git checkout, retaining the pin.
while IFS= read -r manifest; do
  sed -i "s#https://github.com/eclipse-zenoh/zenoh.git#file://${zenoh_source}#g" "${manifest}"
done < <(grep -rl --include='Cargo.toml*' --include='Cargo.lock' \
  'https://github.com/eclipse-zenoh/zenoh.git' "${zenohc_source}")

cmake -S "${zenohc_source}" -B "${zenohc_source}/build" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${prefix}" \
  -DBUILD_SHARED_LIBS=ON \
  -DZENOHC_BUILD_WITH_UNSTABLE_API=ON \
  -DZENOHC_CARGO_FLAGS='--features=shared-memory zenoh/transport_serial'
cmake --build "${zenohc_source}/build" --parallel "$(nproc)"
cmake --install "${zenohc_source}/build"

grep -q 'name = "aws-lc-rs"' "${zenohc_source}/Cargo.lock"

git clone https://github.com/eclipse-zenoh/zenoh-cpp.git "${zenohcxx_source}"
git -C "${zenohcxx_source}" checkout --detach "${zenohcxx_commit}"
cmake -S "${zenohcxx_source}" -B "${zenohcxx_source}/build" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${prefix}" \
  -DZENOHCXX_ZENOHC=OFF \
  -DCMAKE_PREFIX_PATH="${prefix}"
cmake --build "${zenohcxx_source}/build" --parallel "$(nproc)"
cmake --install "${zenohcxx_source}/build"

git clone --branch "${rmw_zenoh_ref}" --single-branch \
  https://github.com/ros2/rmw_zenoh.git "${rmw_source}"

source "/opt/ros/${ROS_DISTRO}/setup.bash"
cd "${rmw_source}"
colcon build \
  --install-base "${overlay}/install" \
  --build-base "${overlay}/build" \
  --packages-select zenoh_cpp_vendor zenoh_security_tools rmw_zenoh_cpp \
  --cmake-args \
    -DUSE_SYSTEM_ZENOH=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="${prefix}"

test -f "${overlay}/install/setup.bash"
