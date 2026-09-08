# Project status and community path

Status checked: 8 September 2026.

## The opportunity is still open

The work is timely. The OMG DDS Security 1.3 Revision Task Force has an open
issue, `DDSSEC13-91`, specifically requesting post-quantum algorithms. There is
official standards interest but no adopted DDS PQ algorithm profile yet. That
is a good moment for implementation evidence, wire-format feedback, benchmarks,
and interoperability vectors.

The claim should be “early practical ROS 2/DDS PQC work,” not “the only work.”
The thesis and JNIC 2024 paper predate the open standards item, a September
2025 journal article reports standardized PQC in ROS 2 DDS, and a 2026 paper
benchmarks PQ handshakes in Fast DDS and CycloneDDS. A separate 2026 SROS2
proposal is also open. Your work still has a distinctive systems contribution:
CycloneDDS and OpenDDS adapters, SROS2 integration, and a direct comparison
with native Zenoh middleware.

## SROS2 is not obsolete

SROS2 is active, released, and owned by the ROS 2 Security Working Group. What
has changed is that its artifact format maps directly to DDS Security. For
`rmw_zenoh_cpp`, ROS provides `zenoh_security_tools` to translate an SROS2
policy and enclave material into Zenoh ACL, authentication, and encryption
configuration. SROS2 remains useful as policy/credential tooling; the
middleware-specific adapter is now an explicit architectural layer.

This fork was rebased onto current upstream `rolling`. Its PQ implementation
now uses OpenSSL's native FIPS 204 algorithm names (`ML-DSA-44`, `ML-DSA-65`,
and `ML-DSA-87`) instead of hardcoded oqsprovider paths. It keeps the identity
CA separate from the permissions CA because OpenSSL's current CMS signing path
cannot use native ML-DSA.

## Zenoh, rustls, and mTLS status

ROS 2 Lyrical supports `rmw_zenoh_cpp` and CycloneDDS at Tier 1 and pins Zenoh
1.8. The official `zenoh_security_tools` already converts an SROS2 policy and
enclave certificates into Zenoh access-control and TLS configuration, including
mTLS. This is the supported integration point; Zenoh does not consume DDS
governance or permissions files directly.

rustls 0.23 has hybrid `X25519MLKEM768` key exchange in its AWS-LC provider,
and `prefer-post-quantum` puts it first. The older `rustls-post-quantum` crate is
no longer needed for ML-KEM with rustls 0.23.22 or newer. Zenoh 1.8 and current
Zenoh 1.9 still select rustls's `ring` provider, so this demo applies a focused
provider patch and verifies the negotiated group at runtime.

The result is hybrid-PQ TLS key establishment with conventional P-256 X.509
mTLS authentication. Stable Zenoh/rustls certificate verification does not yet
provide an end-to-end ML-DSA certificate path, so the demo does not claim PQ
authentication for Zenoh.

## Recommended presentation sequence

1. Publish a short design note with an honest threat/claims matrix: identity
   authentication, handshake key establishment, data encryption, signed policy,
   downgrade behavior, and which pieces are standardized.
2. Run the one-command demos in CI on x86-64 and ARM. Publish benchmark output,
   packet captures or transcript hashes, and the included negative tests.
3. Comment on the existing SROS2 PQC discussion before opening a competing
   proposal. Then request a slot at an open Security Working Group meeting.
   Lead with reproducible results and concrete upstream questions.
4. Offer small upstreamable changes independently: SROS2 crypto-backend
   abstraction and tests, selectable rustls provider wiring for Zenoh, shared
   test vectors, and documentation. Keep the experimental DDS wire protocol in
   its own plugin until the OMG profile settles.
5. Contact the CycloneDDS, OpenDDS, and `rmw_zenoh` maintainers with the piece
   relevant to each project. Coordinate the protocol vocabulary and test
   vectors with the OMG issue rather than inventing a competing “official”
   profile.
6. Turn the result into a ROSCon/ROSCon regional talk proposal: standards gap,
   two architectural paths, measured costs on representative robots, and a
   migration strategy. A Security WG presentation is the best first review.

## Engineering work still needed before an upstream claim

- Add cross-adapter CycloneDDS/OpenDDS byte-for-byte transcript vectors and an
  interoperability test. The two implementations currently remain separate.
- Add downgrade and malformed-handshake tests, certificate-chain edge cases,
  algorithm-agility negotiation, and protocol versioning.
- Benchmark discovery latency, CPU, memory, handshake bytes, reconnect storms,
  and loss/fragmentation on x86-64 plus at least one representative ARM robot.
- Define hybrid policy explicitly. Pure ML-KEM demonstrates PQ operation;
  X25519MLKEM768 is a safer migration default while implementations mature.
- Obtain cryptographic and DDS Security review before using the plugin beyond a
  controlled experiment.

## Primary references

- [ROS 2 Lyrical release](https://github.com/ros2/ros2_documentation/blob/rolling/source/Get-Started/Releases/Release-Lyrical-Luth.rst)
- [Lyrical supported platforms and middleware versions](https://github.com/ros2/ros2_documentation/blob/rolling/source/Get-Started/Releases/lyrical/supported-platforms.rst)
- [SROS2 upstream](https://github.com/ros2/sros2)
- [ROS 2 Security Working Group](https://github.com/ros-security/community)
- [rmw_zenoh security configuration tool](https://github.com/ros2/rmw_zenoh/blob/rolling/zenoh_security_tools/README.md)
- [OMG DDS PQC issue DDSSEC13-91](https://issues.omg.org/issues/spec/DDS-SECURITY/1.2)
- [OpenSSL 3.5 release announcement](https://openssl-library.org/post/2025-04-08-openssl-35-final-release/)
- [OpenSSL CMS and ML-DSA issue](https://github.com/openssl/openssl/issues/28279)
- [rustls hybrid-PQ defaults](https://docs.rs/rustls/latest/rustls/manual/_05_defaults/index.html)
- [AWS-LC post-quantum algorithms](https://github.com/aws/aws-lc/blob/main/crypto/fipsmodule/PQREADME.md)
- [Master's thesis repository record](https://dspace.umh.es/handle/11000/37017)
- [2025 standardized-PQC ROS 2 paper](https://doi.org/10.1007/s10207-025-01133-w)
- [2026 ROS 2/DDS PQC handshake paper](https://doi.org/10.13089/JKIISC.2026.36.3.821)
- [Open SROS2 PQC proposal](https://github.com/ros2/sros2/issues/392)
