# rmw_zenoh hybrid-PQ mTLS demo

From the repository root, run:

```bash
make test-zenoh
```

The build replaces Zenoh 1.8's rustls `ring` feature with `aws_lc_rs` and
`prefer-post-quantum`. The test requires evidence of an X25519MLKEM768 TLS 1.3
negotiation, rejection of an anonymous TLS client, denial of a topic outside
the generated ACL, and a talker/listener message. Authentication uses mutual
ECDSA certificates; PQ certificate signatures are outside this demo.
