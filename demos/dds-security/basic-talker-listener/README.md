# DDS Security with Post-Quantum Cryptography Demo

This demo implements the test scenario from thesis Section 5.1.2, demonstrating secure ROS 2 communication using:

- **PQSec-DDS plugin** for post-quantum DDS security
- **Enhanced SROS2** with ML-DSA44 (Dilithium3) signatures
- **ML-KEM-768** key encapsulation for secure communication
- **CycloneDDS** middleware with custom authentication plugin

## Architecture

The demo consists of:

1. **Certificate Generation**: Enhanced SROS2 creates PQC certificates
2. **Authentication**: PQSec-DDS plugin handles mutual authentication  
3. **Secure Communication**: Encrypted message exchange between nodes
4. **Network Support**: Can run in single container or across network

## Files

```
demos/dds-security/basic-talker-listener/
├── run_test.py              # Main test script
├── README.md               # This file
└── config/
    ├── single-container.xml    # Local DDS config
    └── networked.xml          # Multi-container DDS config
```

## Usage

### Single Container Test

Run both talker and listener in the same container:

```bash
# Build and run
docker-compose up dds-