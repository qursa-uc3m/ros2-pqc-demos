#!/usr/bin/env bash
set -euo pipefail

mode=${1:-}
case "${mode}" in
  dds|zenoh) ;;
  *) echo "usage: $0 dds|zenoh" >&2; exit 2 ;;
esac

project_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${project_root}"
result_dir=$(mktemp -d /tmp/ros2-pqc-demo.XXXXXX)

cleanup() {
  local status=$?
  if [[ "${KEEP_CONTAINERS:-0}" != 1 ]]; then
    docker compose down --volumes --remove-orphans >/dev/null 2>&1 || true
  fi
  if [[ ${status} -eq 0 ]]; then
    rm -rf "${result_dir}"
  else
    echo "Test logs retained in ${result_dir}" >&2
  fi
  return "${status}"
}
trap cleanup EXIT

docker compose down --volumes --remove-orphans
docker compose build base
docker compose build "${mode}-pqc"
docker compose run --rm artifacts

if [[ "${mode}" == dds ]]; then
  docker compose up -d dds-talker dds-listener
  docker compose exec -T dds-listener \
    timeout 25 /workspace/scripts/dds/run_listener.sh \
    >"${result_dir}/listener.log" 2>&1 &
  listener_pid=$!
  sleep 3
  docker compose exec -T dds-talker \
    timeout 12 /workspace/scripts/dds/run_talker.sh \
    >"${result_dir}/talker.log" 2>&1 || test $? -eq 124
  wait "${listener_pid}" || test $? -eq 124
  grep -m 1 'I heard:.*Hello World' "${result_dir}/listener.log"
  echo 'DDS PQ authentication and encrypted talker/listener test passed.'
else
  docker compose up -d zenoh-router zenoh-talker zenoh-listener
  for attempt in {1..30}; do
    if docker compose exec -T zenoh-talker \
        /workspace/scripts/zenoh/verify_hybrid_tls.sh \
        >"${result_dir}/tls.log" 2>&1; then
      break
    fi
    if [[ ${attempt} -eq 30 ]]; then
      docker compose logs zenoh-router >&2
      echo 'Zenoh router did not become ready' >&2
      exit 1
    fi
    sleep 1
  done
  docker compose exec -T zenoh-talker \
    /workspace/scripts/zenoh/verify_mtls_rejects_anonymous.sh \
    >"${result_dir}/mtls-negative.log" 2>&1

  # The generated policy allows /chatter, not /blocked. If ACL enforcement were
  # absent, the equally remapped publisher and listener would communicate.
  docker compose exec -T zenoh-listener \
    timeout 10 /workspace/scripts/zenoh/run_listener.sh \
      --ros-args --remap chatter:=blocked \
    >"${result_dir}/acl-listener.log" 2>&1 &
  acl_listener_pid=$!
  sleep 2
  docker compose exec -T zenoh-talker \
    timeout 6 /workspace/scripts/zenoh/run_talker.sh \
      --ros-args --remap chatter:=blocked \
    >"${result_dir}/acl-talker.log" 2>&1 || test $? -eq 124
  wait "${acl_listener_pid}" || test $? -eq 124
  if grep -q 'I heard:' "${result_dir}/acl-listener.log"; then
    echo 'Zenoh ACL allowed a publication outside the SROS2 policy' >&2
    exit 1
  fi

  docker compose exec -T zenoh-listener \
    timeout 25 /workspace/scripts/zenoh/run_listener.sh \
    >"${result_dir}/listener.log" 2>&1 &
  listener_pid=$!
  sleep 3
  docker compose exec -T zenoh-talker \
    timeout 12 /workspace/scripts/zenoh/run_talker.sh \
    >"${result_dir}/talker.log" 2>&1 || test $? -eq 124
  wait "${listener_pid}" || test $? -eq 124
  grep -m 1 'X25519MLKEM768' "${result_dir}/tls.log"
  grep -mi 1 -E 'certificate required|certificate.*required|alert.*certificate' \
    "${result_dir}/mtls-negative.log"
  grep -m 1 'I heard:.*Hello World' "${result_dir}/listener.log"
  echo 'Zenoh hybrid-PQ TLS, mTLS, ACL, and talker/listener test passed.'
fi
