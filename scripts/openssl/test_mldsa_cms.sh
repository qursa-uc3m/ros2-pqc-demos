#!/usr/bin/env bash
set -euo pipefail

work_dir=$(mktemp -d /tmp/openssl4-cms.XXXXXX)
cleanup() {
  rm -rf "${work_dir}"
}
trap cleanup EXIT

cd "${work_dir}"
printf '%s\n' 'ROS 2 ML-DSA CMS capability test' > payload.txt

openssl version | grep -q '^OpenSSL 4\.0\.1 '
openssl genpkey -algorithm ML-DSA-44 -out signer.key.pem
openssl req -new -x509 \
  -key signer.key.pem \
  -subj '/CN=ROS 2 ML-DSA CMS experiment' \
  -days 1 \
  -out signer.cert.pem
openssl cms -sign -binary -nodetach \
  -in payload.txt \
  -signer signer.cert.pem \
  -inkey signer.key.pem \
  -outform DER \
  -out payload.cms
openssl cms -verify -binary \
  -inform DER \
  -in payload.cms \
  -CAfile signer.cert.pem \
  -purpose any \
  -out verified.txt
cmp payload.txt verified.txt

echo 'OpenSSL 4.0 ML-DSA-44 CMS sign/verify test passed.'
