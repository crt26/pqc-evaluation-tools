# Supported PQC Algorithms

## Support Overview
This document outlines the algorithms supported in this project based on the upstream cryptographic dependencies (liboqs, OQS-Provider, and OpenSSL). It also details exclusions and the rationale behind them.

The PQC-Evaluation-Tools project provides support for all the PQC algorithms provided by its various dependency libraries. However, there are some exceptions to this which are detailed in the following subsections. For detailed information of the algorithms this project supports, please refer to the following dependency library documentation:

- [Liboqs Supported Algorithms](https://github.com/open-quantum-safe/liboqs?tab=readme-ov-file#supported-algorithms)
- [OpenSSL Supported PQC Algorithms](https://github.com/openssl/openssl/releases/tag/openssl-3.5.0)
- [OQS-Provider Supported Algorithms](https://github.com/open-quantum-safe/oqs-provider/blob/main/ALGORITHMS.md)

## Liboqs Algorithms
All algorithms provided by Liboqs are supported within the project by default apart from **HQC** and its variations. This is due to the current implementation of the scheme in Liboqs containing a IND-CCA2 vulnerability which affects the security of the HQC KEM family. By default this project will not enable HQC for use in computational performance testing. However, the project does provide functionality to enable HQC should the user wish to do so.

Additionally, memory profiling for **Falcon** algorithm variants is currently non-functional on **ARM** systems due to issues with the scheme and the Valgrind Massif tool. Please see the [bug report](https://github.com/open-quantum-safe/liboqs/issues/1761) for details. Testing and parsing remain fully functional for all other algorithms.

For more information on enabling HQC and the issue as a whole, please refer to the following documentation:

- See the [Advanced Setup Configuration Guide](../advanced-setup-configuration.md) for instructions on enabling HQC.
- Refer to the [Disclaimer Document](../../DISCLAIMER.md) for security warnings and usage guidance.

## OpenSSL Algorithms
OpenSSL 3.5.0 now provides support for the NIST standardised PQC algorithms ML-KEM, ML-DSA, and SLH-DSA. This project provides support for integrating these implementations from OpenSSL within its automated TLS benchmarking functionality. However, some limitations do exist for their performance testing when using the OpenSSL `speed` utility.

When benchmarking tests are carried out using this tool, **ML-DSA** and **SLH-DSA** cannot be tested, as the `speed` utility does not support these algorithms currently. This is shown from the following output when attempting to use the schemes with the tool:

```
407C0B051C750000:error:03000096:digital envelope routines:evp_pkey_signature_init:operation not supported for this keytype:crypto/evp/signature.c:722:
```

Furthermore, although **SLH-DSA** is supported at the provider level in OpenSSL 3.5.0 and can be used to generate and verify X.509 certificates, it is not yet supported for use in TLS handshakes (e.g., via `s_server`, `s_client`, or automated TLS benchmarking). This limitation is due to the current lack of integration into the OpenSSL TLS (libssl) layer. The integration of SLH-DSA into TLS 1.3 is in progress and being tracked by the [IETF draft](https://datatracker.ietf.org/doc/html/draft-reddy-tls-slhdsa-01). To allow continued evaluation of stateless hash-based signature schemes in TLS contexts, the implementation of SPHINCS+ available in the OQS-Provider library will be used ain place of SLH-DSA. This will remain the case in this project until full support of the SLH-DSA is available in OpenSSL.

Hopefully, support will be added for the schemes to be tested using this tool in futures updates in both this project and the OpenSSL project.

In addition to the natively supported PQC algorithms, the project provides TLS benchmarking for classical schemes to provide meaningful performance baselines against PQC schemes. These include:

- RSA-2048
- RSA-3072
- RSA-4096
- prime256v1
- secp384r1
- secp521r1

## OQS-Provider Algorithms
The majority of algorithms provided by the OQS-Provider are supported by this project for use in automated TLS and cryptographic benchmarking. However, a small number of algorithms are explicitly excluded due to known incompatibilities with TLS 1.3 or unsupported behavior in OpenSSL's benchmarking tools.

The following signature algorithms are excluded from the automated TLS benchmarking due to incompatibilities with [RFC 8446](https://datatracker.ietf.org/doc/html/rfc8446), which defines TLS 1.3. These schemes do not meet the specification's requirements for digital signatures in TLS handshakes:

- **UOV-based schemes** (e.g., `OV_Is`, `OV_III`, and their hybrid variants)
- **CROSSrsdp256small**

These algorithms remain available within the OQS-Provider and may be usable in non-TLS applications, but they are automatically filtered out from handshake-based tests and benchmarking in this project.

Furthermore, with the addition of native PQC support in OpenSSL 3.5.0, the OQS-Provider **automatically disables its own implementations** of overlapping schemes (e.g., ML-KEM, ML-DSA, SLH-DSA) when compiled against this version.

For further information on this, please refer to the following OQS-Provider documentation:

- [OQS-Provider Notice](https://github.com/open-quantum-safe/oqs-provider?tab=readme-ov-file#35-and-greater)
