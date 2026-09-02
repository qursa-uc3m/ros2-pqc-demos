# ROS 2 post-quantum security demos

Reproducible experiments for two different ROS 2 security paths:

| Demo | Middleware | Key establishment | Peer authentication | Access control |
|---|---|---|---|---|
| DDS | CycloneDDS + PQSec-DDS | ML-KEM-768 | ML-DSA-44 X.509 | DDS Security, ECDSA CMS |
| Zenoh | `rmw_zenoh_cpp` + patched rustls | X25519MLKEM768 | ECDSA P-256 mTLS | Zenoh ACL generated from an SROS2 policy |

This is an experimental research project, not an implementation of an
official PQ-enabled DDS Security profile. The current DDS Security
specification does not yet standardize the PQ handshake used by PQSec-DDS.

## Why ROS 2 Lyrical

The primary baseline is ROS 2 Lyrical Luth on Ubuntu 26.04. It is the current
ROS 2 LTS, gives both CycloneDDS and `rmw_zenoh_cpp` Tier 1 support, and ships
OpenSSL 3.5 with native ML-KEM and ML-DSA. This removes the old local OpenSSL,
liboqs, and oqsprovider build from the standardized-algorithm path.

Jazzy remains useful for comparison with the thesis results, but Ubuntu 24.04's
OpenSSL 3.0 means it needs a separate OpenSSL 3.5 installation and its Zenoh
RMW is not the same supported baseline.

## Run

Requirements: Docker Engine with the Compose plugin and enough disk space for
the Rust/Zenoh build. The first Zenoh build is intentionally substantial.

```bash
make test-dds
make test-zenoh
```

`make test-dds` builds the pinned current PQSec-DDS Cyclone adapter, generates
the security artifacts, and requires a listener to receive a message.
`make test-zenoh` additionally builds the Zenoh 1.8 stack with rustls's AWS-LC
provider, proves that `X25519MLKEM768` was negotiated, and then requires a
message through the mTLS- and ACL-protected router.

Useful overrides:

```bash
KEM_ALGORITHM=x25519_mlkem768 make test-dds
IDENTITY_ALGORITHM=ML-DSA-65 make test-dds
KEEP_CONTAINERS=1 make test-zenoh
```

The test command recreates the Compose certificate volume. Use
`KEEP_CONTAINERS=1` to preserve containers and logs after a run.

## Security architecture and limitations

Artifact generation starts from one SROS2 policy and one keystore:

1. The rebased SROS2 fork asks the OpenSSL 3.5 default provider to create the
   DDS identity CA and participant certificates with ML-DSA.
2. The SROS2 permissions CA remains ECDSA and signs DDS governance and
   permissions through CMS/S/MIME. Native OpenSSL ML-DSA cannot currently sign
   CMS because ML-DSA is digestless while that CMS path requests a digest.
3. `zenoh_security_tools` converts the policy into Zenoh ACLs and mTLS config.
   Zenoh uses ECDSA certificates for stable X.509 interoperability, while the
   patched rustls/AWS-LC transport supplies hybrid post-quantum key exchange.

Consequently, “PQC” does not mean the same thing in both demos. The DDS
experiment covers PQ authentication and KEM inside a non-standard plugin
handshake. The Zenoh experiment gives harvest-now-decrypt-later resistance for
session establishment but does not claim PQ certificate authentication.

## Repository layout

- `docker/`: Lyrical base, CycloneDDS adapter, and Zenoh/rustls images
- `config/`: CycloneDDS configuration, Zenoh seeds, and the shared SROS2 policy
- `scripts/`: pinned builds, artifact generation, and pass/fail test runners
- `sros2/`: fork rebased onto upstream `rolling`, with native OpenSSL ML-DSA
- `docs/project-status.md`: standards, community, and presentation strategy

PQSec-DDS also contains an OpenDDS adapter. It is not part of this ROS RMW demo
because that adapter currently needs OpenDDS external-security-loader changes;
see its own adapter documentation for the standalone test.

## Background

This work follows Javier Blanco-Romero's master's thesis and the paper
“PQSec-DDS: Integrating Post-Quantum Cryptography into DDS Security for
Robotic Applications,” presented at JNIC 2024. The [project-status report](docs/project-status.md)
sets the work against the current ROS 2, DDS Security, OpenSSL, and Zenoh state.
