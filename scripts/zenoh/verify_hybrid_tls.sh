#!/usr/bin/env bash
set -euo pipefail
source /workspace/scripts/setup/setup_base_env.sh

tls_dir=/workspace/certs/zenoh-enclaves/talker
output=$(timeout 12 openssl s_client \
  -connect zenoh-router:7447 \
  -cert "${tls_dir}/cert.pem" \
  -key "${tls_dir}/key.pem" \
  -CAfile "${tls_dir}/identity_ca.cert.pem" \
  -groups X25519MLKEM768 \
  -brief </dev/null 2>&1 || true)
printf '%s\n' "${output}"
grep -q 'X25519MLKEM768' <<<"${output}" || {
  echo 'TLS connected without evidence of the expected hybrid group' >&2
  exit 1
}
