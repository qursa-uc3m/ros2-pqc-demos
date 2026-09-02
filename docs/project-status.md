# Project status and community path

Status checked: 2 September 2026.

## The opportunity is still open

The work is timely. The OMG issue tracker has an open DDS Security 1.2 issue,
`DDSSEC13-91`, specifically requesting post-quantum algorithms. In other words,
there is official interest but no standardized DDS PQ algorithm profile yet.
That is a particularly good moment for implementation evidence, wire-format
feedback, benchmarks, and interoperability vectors.

The claim should be “early practical ROS 2/DDS PQC work,” not “the only work.”
The thesis and JNIC 2024 paper predate the currently visible standards item,
but a 2026 paper now also studies PQC-based DDS Security handshakes in ROS 2.
Your strongest position is the breadth of the work: implementations across
CycloneDDS and OpenDDS, integration with SROS2, and a comparison with Zenoh.

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

## Recommended presentation sequence

1. Publish a short design note with an honest threat/claims matrix: identity
   authentication, handshake key establishment, data encryption, signed policy,
   downgrade behavior, and which pieces are standardized.
2. Make the two one-command demos and benchmark output reproducible in CI. Add
   packet captures or transcript hashes and negative tests before presenting
   interoperability claims.
3. Open a focused design discussion in `ros-security/community`, then request a
   slot at an open Security Working Group meeting. Lead with the reproducible
   results and the concrete upstream questions, not with a request to merge a
   large fork.
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
- [OMG DDS Security issues](https://issues.omg.org/issues/spec/DDS-SECURITY?view=ALL)
- [OpenSSL 3.5 release notes](https://openssl-library.org/news/openssl-3.5-notes/)
- [OpenSSL CMS and ML-DSA issue](https://github.com/openssl/openssl/issues/28279)
- [rustls provider guidance](https://github.com/rustls/rustls)
- [AWS-LC post-quantum algorithms](https://github.com/aws/aws-lc/blob/main/crypto/fipsmodule/PQREADME.md)
- [Master's thesis repository record](https://dspace.umh.es/handle/11000/37017)
- [2026 ROS 2/DDS PQC handshake paper](https://doi.org/10.13089/JKIISC.2026.36.3.821)
