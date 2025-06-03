# ros2-pqc-demos

A demonstration and testing repository for Post-Quantum Cryptography (PQC) integrations in ROS 2 communications stack. It includes examples for both DDS Security and Zenoh middleware approaches and with certificate management using SROS2.

## Related Repositories

This repository uses the following related repositories with the PQC integrations:

- **[qursa-uc3m/pqsec-dds](https://github.com/qursa-uc3m/pqsec-dds)**: Post-Quantum Cryptography plugin for DDS Security
- **[fj-blanco/sros2](https://github.com/fj-blanco/sros2)**: SROS2 fork with PQC integration for certificate management
- **[fj-blanco/zenoh](https://github.com/fj-blanco/zenoh)**: Zenoh fork with post-quantum TLS support via [rustls-post-quantum](https://crates.io/crates/rustls-post-quantum) provider for rustls

## Background

This work is based on the preliminary ideas and results presented at the [IX Jornadas Nacionales de Investigación en Ciberseguridad](https://2024.jnic.es/) held from 27-29th May in Sevilla, Spain. The conference paper

- ***PQSec-DDS: Integrating Post-Quantum Cryptography into DDS Security for Robotic Applications*** by F. J. Blanco-Romero, V. Lorenzo, F. Almenares, D. Dı́az-Sánchez and A. Serrano Navarro

was presented on 29th May. You can find the paper at pages 396-403 of the proceedings [Actas de las IX Jornadas Nacionales de Investigación en Ciberseguridad](https://idus.us.es/handle/11441/159179).

This repository also incorporates  research and implementations from the master's thesis:

- **"Enhancing Communication Security in ROS 2"** by Javier Blanco-Romero- Master's Thesis, Universidad Miguel Hernández de Elche (2024/2025)

which analyzes post-quantum cryptography integration in ROS 2 through a DDS Security plugin, Zenoh middleware adaptations, and SROS2 security package modifications to achieve quantum-resistant communication in robotic systems.

## Contributing

Contributions are welcome!