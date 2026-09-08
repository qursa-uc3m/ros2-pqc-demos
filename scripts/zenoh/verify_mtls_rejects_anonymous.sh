#!/usr/bin/env bash
set -euo pipefail
source /workspace/scripts/setup/setup_base_env.sh

ca_file=/workspace/certs/zenoh-enclaves/talker/identity_ca.cert.pem
set +e
output=$(timeout 12 openssl s_client \
  -connect zenoh-router:7447 \
  -CAfile "${ca_file}" \
  -groups X25519MLKEM768 \
  -brief </dev/null 2>&1)
status=$?
set -e
printf '%s\n' "${output}"

if [[ ${status} -eq 0 ]] || grep -q 'CONNECTION ESTABLISHED' <<<"${output}"; then
  echo 'Zenoh accepted a TLS client without a certificate' >&2
  exit 1
fi
grep -qiE 'certificate required|certificate.*required|alert.*certificate' <<<"${output}" || {
  echo 'Anonymous TLS failed without evidence of mTLS enforcement' >&2
  exit 1
}
