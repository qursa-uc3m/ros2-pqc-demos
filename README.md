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
provider, proves that `X25519MLKEM768` was negotiated, proves that an anonymous
TLS client is rejected, checks an ACL-denied topic, and then requires a message
through the protected router.

The integration workflow runs both commands natively on x86-64 and ARM64.

Useful overrides:

```bash
IDENTITY_ALGORITHM=ML-DSA-65 make test-dds
KEEP_CONTAINERS=1 make test-zenoh
SKIP_BUILD=1 make test-zenoh
```

The DDS adapter also supports native hybrid KEMs when built against OpenSSL
3.6 or newer. The default Lyrical image uses OpenSSL 3.5, so this demo defaults
to `mlkem768`.

The test command recreates the Compose certificate volume. Use
`KEEP_CONTAINERS=1` to preserve containers after a run. On failure, the runner
prints the temporary directory where it retained the command logs. Use
`SKIP_BUILD=1` only to rerun runtime checks against images you already built.

## Security architecture and limitations

Artifact generation starts from one SROS2 policy and one keystore:

1. A patch based on current upstream SROS2 asks the OpenSSL 3.5 default provider
   to create the DDS identity CA and participant certificates with ML-DSA.
2. The SROS2 permissions CA remains ECDSA and signs DDS governance and
   permissions through CMS/S/MIME. This split is required by the OpenSSL 3.5
   CMS implementation in the Lyrical image; it is not a general limitation of
   ML-DSA or newer OpenSSL releases. `make test-openssl4-cms` is a separate,
   pinned OpenSSL 4.0 experiment that proves ML-DSA-44 CMS sign/verify works.
3. `zenoh_security_tools` converts the policy into Zenoh ACLs and mTLS config.
   Zenoh uses ECDSA certificates for stable X.509 interoperability, while the
   patched rustls/AWS-LC transport supplies hybrid post-quantum key exchange.

Consequently, “PQC” does not mean the same thing in both demos. The DDS
experiment covers PQ authentication and KEM inside a non-standard plugin
handshake. The Zenoh experiment gives harvest-now-decrypt-later resistance for
session establishment but does not claim PQ certificate authentication.

| Security property | DDS path | Zenoh path |
|---|---|---|
| Identity authentication | ML-DSA X.509 in the experimental PQSec-DDS handshake | ECDSA P-256 X.509 mTLS |
| Session key establishment | Pure ML-KEM-768 | Hybrid X25519MLKEM768 |
| Data confidentiality and integrity | DDS Security AES-GCM; default governance encrypts discovery, metadata, and topic data | TLS 1.3 records between each client and the router |
| Authorization policy | DDS governance and permissions signed by a separate ECDSA CMS CA | Generated local Zenoh ACL configuration; protect the generated files as deployment secrets |
| Downgrade behavior | No classical KEM fallback or algorithm negotiation in this experimental handshake | PQ is preferred, but classical TLS groups remain available for compatibility; the test asserts PQ was selected between patched peers |
| Standardization boundary | ML-KEM and ML-DSA are standardized; the DDS handshake and token identifiers are not an adopted OMG profile | The component algorithms are standardized; the provider patch and ROS/Zenoh integration are experimental |

Neither path claims end-to-end application-message signatures independent of
its secure transport. The tests establish the negotiated mechanisms and policy
behavior, not production readiness or third-party interoperability.

## Repository layout

- `docker/`: Lyrical base, CycloneDDS adapter, and Zenoh/rustls images
- `config/`: CycloneDDS configuration, Zenoh seeds, and the shared SROS2 policy
- `scripts/`: pinned builds, artifact generation, and pass/fail test runners
- `patches/`: pinned SROS2 and Zenoh/rustls integration deltas
- `docs/project-status.md`: standards, community, and presentation strategy
- `.github/workflows/integration.yml`: native x86-64 and ARM64 Docker tests

PQSec-DDS also contains an OpenDDS adapter. It is not part of this ROS RMW demo
because that adapter currently needs OpenDDS external-security-loader changes;
see its own adapter documentation for the standalone test.

## Background

This work follows Javier Blanco-Romero's master's thesis and the paper
“PQSec-DDS: Integrating Post-Quantum Cryptography into DDS Security for
Robotic Applications,” presented at JNIC 2024. The [project-status report](docs/project-status.md)
sets the work against the current ROS 2, DDS Security, OpenSSL, and Zenoh state.
Repository and paper citation metadata are provided in [`CITATION.cff`](CITATION.cff).
