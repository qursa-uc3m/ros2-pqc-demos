# CycloneDDS PQ authentication demo

From the repository root, run:

```bash
make test-dds
```

The test generates ML-DSA participant identities, builds the current pinned
PQSec-DDS CycloneDDS authentication adapter with ML-KEM-768, starts isolated
talker/listener containers, and passes only after the listener receives a
message. See the root README for the signed-policy limitation and exact claims.
