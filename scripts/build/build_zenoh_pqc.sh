#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 6 || $# -gt 7 ]]; then
  echo "usage: $0 ZENOH_COMMIT ZENOHC_COMMIT ZENOHCXX_COMMIT RMW_ZENOH_COMMIT PREFIX OVERLAY [core|rmw|all]" >&2
  exit 2
fi

zenoh_commit=$1
zenohc_commit=$2
zenohcxx_commit=$3
rmw_zenoh_commit=$4
prefix=$5
overlay=$6
phase=${7:-all}
case "${phase}" in
  core|rmw|all) ;;
  *) echo "unsupported build phase: ${phase}" >&2; exit 2 ;;
esac
source_root=/opt/src
zenoh_source=${source_root}/zenoh
zenohc_source=${source_root}/zenoh-c
zenohcxx_source=${source_root}/zenoh-cpp
rmw_source=${source_root}/rmw_zenoh

mkdir -p "${source_root}" "${prefix}" "${overlay}"

if [[ "${phase}" == core || "${phase}" == all ]]; then
git clone https://github.com/eclipse-zenoh/zenoh.git "${zenoh_source}"
git -C "${zenoh_source}" checkout --detach "${zenoh_commit}"
# The focused provider patch intentionally has zero-context mechanical hunks;
# the pinned commit and the check phase keep their targets deterministic.
git -C "${zenoh_source}" apply --check --unidiff-zero \
  /opt/patches/zenoh-rustls-aws-lc-pqc.patch
git -C "${zenoh_source}" apply --unidiff-zero \
  /opt/patches/zenoh-rustls-aws-lc-pqc.patch

git clone https://github.com/eclipse-zenoh/zenoh-c.git "${zenohc_source}"
git -C "${zenohc_source}" checkout --detach "${zenohc_commit}"

# A file:// Git dependency would read a committed revision and silently ignore
# the provider patch in this working tree. Point zenoh-c's direct dependencies,
# including its opaque-type helper crate, at the patched workspace paths.
# Internal Zenoh dependencies are already workspace-relative paths.
for manifest in Cargo.toml Cargo.toml.in build-resources/opaque-types/Cargo.toml; do
  manifest_path=${zenohc_source}/${manifest}
  sed -Ei \
    "s#git = \"https://github.com/eclipse-zenoh/zenoh.git\", (branch|rev) = \"[^\"]+\"#path = \"${zenoh_source}/zenoh\"#" \
    "${manifest_path}"
  sed -i \
    "s#zenoh-ext = { version = \"1.8.0\", path = \"${zenoh_source}/zenoh\"#zenoh-ext = { version = \"1.8.0\", path = \"${zenoh_source}/zenoh-ext\"#" \
    "${manifest_path}"
  sed -i \
    "s#zenoh-protocol = { version = \"1.8.0\", path = \"${zenoh_source}/zenoh\"#zenoh-protocol = { version = \"1.8.0\", path = \"${zenoh_source}/commons/zenoh-protocol\"#" \
    "${manifest_path}"
  sed -i \
    "s#zenoh-runtime = { version = \"1.8.0\", path = \"${zenoh_source}/zenoh\"#zenoh-runtime = { version = \"1.8.0\", path = \"${zenoh_source}/commons/zenoh-runtime\"#" \
    "${manifest_path}"
  sed -i \
    "s#zenoh-util = { version = \"1.8.0\", path = \"${zenoh_source}/zenoh\"#zenoh-util = { version = \"1.8.0\", path = \"${zenoh_source}/commons/zenoh-util\"#" \
    "${manifest_path}"
  sed -i \
    "s#zenoh-pinned-deps-1-75 = { version = \"1.8.0\", path = \"${zenoh_source}/zenoh\"#zenoh-pinned-deps-1-75 = { version = \"1.8.0\", path = \"${zenoh_source}/commons/zenoh-pinned-deps-1-75\"#" \
    "${manifest_path}"
  if grep -q 'git = "https://github.com/eclipse-zenoh/zenoh.git"' \
      "${manifest_path}"; then
    echo "Failed to replace every Zenoh Git dependency in ${manifest}" >&2
    exit 1
  fi
done

cmake -S "${zenohc_source}" -B "${zenohc_source}/build" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${prefix}" \
  -DBUILD_SHARED_LIBS=ON \
  -DZENOHC_BUILD_IN_SOURCE_TREE=OFF \
  -DZENOHC_BUILD_WITH_UNSTABLE_API=ON \
  -DZENOHC_CARGO_FLAGS='--features=shared-memory zenoh/transport_serial'
zenohc_manifest=${zenohc_source}/build/release/Cargo.toml
test -f "${zenohc_manifest}"
grep -q "path = \"${zenoh_source}/zenoh\"" "${zenohc_manifest}"
if grep -q 'git = "https://github.com/eclipse-zenoh/zenoh.git"' \
    "${zenohc_manifest}"; then
  echo 'Generated Zenoh C manifest restored the unpatched Git dependency' >&2
  exit 1
fi

# Reconcile the existing lockfile's Git source entries with the local paths
# before zenoh-c copies it into the offline opaque-type helper build.
rustls_features=$(cargo tree \
  --manifest-path "${zenohc_manifest}" \
  --edges features --invert rustls)
grep -q 'rustls feature "aws_lc_rs"' <<<"${rustls_features}"
grep -q 'rustls feature "prefer-post-quantum"' <<<"${rustls_features}"
if grep -q 'rustls feature "ring"' <<<"${rustls_features}"; then
  echo 'The patched Zenoh build still enables rustls ring' >&2
  exit 1
fi
cmake --build "${zenohc_source}/build" --parallel "$(nproc)"
cmake --install "${zenohc_source}/build"

grep -q 'name = "aws-lc-rs"' "${zenohc_source}/build/release/Cargo.lock"

git clone https://github.com/eclipse-zenoh/zenoh-cpp.git "${zenohcxx_source}"
git -C "${zenohcxx_source}" checkout --detach "${zenohcxx_commit}"
cmake -S "${zenohcxx_source}" -B "${zenohcxx_source}/build" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${prefix}" \
  -DZENOHCXX_ZENOHC=OFF \
  -DCMAKE_PREFIX_PATH="${prefix}"
cmake --build "${zenohcxx_source}/build" --parallel "$(nproc)"
cmake --install "${zenohcxx_source}/build"
fi

if [[ "${phase}" == rmw || "${phase}" == all ]]; then
git clone https://github.com/ros2/rmw_zenoh.git "${rmw_source}"
git -C "${rmw_source}" checkout --detach "${rmw_zenoh_commit}"
git -C "${rmw_source}" apply --check /opt/patches/rmw-zenoh-security-tools.patch
git -C "${rmw_source}" apply /opt/patches/rmw-zenoh-security-tools.patch

set +u
source "/opt/ros/${ROS_DISTRO}/setup.bash"
set -u
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
fi
