#!/usr/bin/env bash
set -euo pipefail

source /workspace/scripts/setup/setup_base_env.sh

cert_root=${CERT_ROOT:-/workspace/certs}
keystore=${cert_root}/keystore
zenoh_enclaves=${cert_root}/zenoh-enclaves
zenoh_configs=${cert_root}/zenoh-config
policy=/workspace/config/security/talker-listener.policy.xml
identity_algorithm=${IDENTITY_ALGORITHM:-ML-DSA-44}

if [[ "${cert_root}" == "/" || -z "${cert_root}" ]]; then
  echo "Refusing unsafe CERT_ROOT=${cert_root@Q}" >&2
  exit 2
fi

rm -rf "${keystore}" "${zenoh_enclaves}" "${zenoh_configs}"
mkdir -p "${cert_root}" "${zenoh_enclaves}" "${zenoh_configs}"

echo "Generating DDS identities with ${identity_algorithm}"
ros2 security create_keystore "${keystore}" \
  --identity-algorithm "${identity_algorithm}"
for role in talker listener zenohd; do
  ros2 security create_enclave "${keystore}" "/talker_listener/${role}"
done
ros2 security create_permission \
  "${keystore}" /talker_listener/talker "${policy}"
ros2 security create_permission \
  "${keystore}" /talker_listener/listener "${policy}"

# Zenoh's stable rustls path performs hybrid-PQ TLS key establishment, while
# authentication remains ECDSA X.509. Reuse SROS2's classical permissions CA
# to keep one trust root and avoid claiming unsupported ML-DSA X.509 mTLS.
tls_ca_cert=${keystore}/public/permissions_ca.cert.pem
tls_ca_key=${keystore}/private/permissions_ca.key.pem
for role in talker listener zenohd; do
  source_enclave=${keystore}/enclaves/talker_listener/${role}
  target_enclave=${zenoh_enclaves}/${role}
  mkdir -p "${target_enclave}"
  for artifact in cert.pem key.pem identity_ca.cert.pem \
      permissions_ca.cert.pem governance.p7s permissions.p7s permissions.xml; do
    cp -L "${source_enclave}/${artifact}" "${target_enclave}/${artifact}"
  done
  cp -L --remove-destination \
    "${tls_ca_cert}" "${target_enclave}/identity_ca.cert.pem"
  openssl genpkey -algorithm EC \
    -pkeyopt ec_paramgen_curve:P-256 \
    -out "${target_enclave}/key.pem"
  openssl req -new \
    -key "${target_enclave}/key.pem" \
    -subj "/CN=${role}" \
    -out "${target_enclave}/${role}.csr.pem"
  san="subjectAltName=DNS:${role}"
  if [[ "${role}" == zenohd ]]; then
    san="subjectAltName=DNS:zenohd,DNS:zenoh-router,DNS:localhost,IP:127.0.0.1"
  fi
  openssl x509 -req \
    -in "${target_enclave}/${role}.csr.pem" \
    -CA "${tls_ca_cert}" \
    -CAkey "${tls_ca_key}" \
    -days 365 \
    -set_serial "0x$(openssl rand -hex 16)" \
    -extfile <(printf '%s\n' 'basicConstraints=critical,CA:false' \
      'keyUsage=critical,digitalSignature' 'extendedKeyUsage=serverAuth,clientAuth' "${san}") \
    -out "${target_enclave}/cert.pem"
  rm "${target_enclave}/${role}.csr.pem"
  openssl verify -CAfile "${tls_ca_cert}" "${target_enclave}/cert.pem"
done

if command -v ros2 >/dev/null \
    && ros2 pkg prefix zenoh_security_tools >/dev/null 2>&1; then
  pushd "${zenoh_configs}" >/dev/null
  ros2 run zenoh_security_tools generate_configs \
    --policy "${policy}" \
    --enclaves "${zenoh_enclaves}" \
    --session-config /workspace/config/zenoh/client-config.json5 \
    --router-config /workspace/config/zenoh/router-config.json5 \
    --ros-domain-id "${ROS_DOMAIN_ID:-0}"
  popd >/dev/null
else
  echo 'zenoh_security_tools is required; run artifact generation with the Zenoh image' >&2
  exit 1
fi

openssl verify -CAfile "${keystore}/public/identity_ca.cert.pem" \
  "${keystore}/enclaves/talker_listener/talker/cert.pem" \
  "${keystore}/enclaves/talker_listener/listener/cert.pem"
echo "Artifacts written below ${cert_root}"
