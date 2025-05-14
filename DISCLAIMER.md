
# Project Disclaimer

## General Disclaimer
This project is intended solely for research and benchmarking purposes. The tools and scripts provided in this repository are designed to evaluate the performance characteristics of Post-Quantum Cryptography (PQC) algorithms in controlled environments. They are not intended for production use or security-critical applications.

The maintainers of this project assume no liability for any consequences resulting from the use or misuse of this repository or its components.

Users are expected to understand the implications of enabling, modifying, or extending any parts of the framework, especially when integrating with cryptographic libraries and systems.

## HQC Algorithm Inclusion Disclaimer
The HQC KEM algorithms are disabled by default in recent versions of the Liboqs library due to a known security issue that breaks IND-CCA2 guarantees under specific attack models.

Despite this, the PQC Evaluation Tools framework provides an optional mechanism to enable HQC algorithms for the sole purpose of performance testing. When using the `--enable-hqc-algs` flag during setup, users will receive a clear warning and must explicitly confirm before HQC is included in the benchmarking environment.

If HQC is enabled:

- It must only be used within the provided testing tools.
- It must not be used in any production systems or real-world cryptographic deployments.

Enabling HQC is done at the user's own risk, and the project maintainers accept no responsibility for any issues arising from its inclusion.

For more information, see:
- [Liboqs Pull Request #2122](https://github.com/open-quantum-safe/liboqs/pull/2122)
- [Liboqs Issue #2118](https://github.com/open-quantum-safe/liboqs/issues/2118)
- [PQC-Evaluation-Tools Issue #46](https://github.com/crt26/pqc-evaluation-tools/issues/46)