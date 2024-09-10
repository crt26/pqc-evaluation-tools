# Release v0.2.1
Welcome to the version 0.2.1 release of the pqc-evaluation-tools project!

## Release Description 
### Overview
The version 0.2.0 release updated the pqc-evaluation-tools benchmark suite to utilise the most recent versions of the OQS project's PQC implementations. Including, the latest algorithms supported by Liboqs, the use of the improved OQS-Provider library compared to the previous OQS-OpenSSL library, and support for the testing and parsing of Hybrid-PQC algorithms within TLS. This version also improved the general setup of the suite alongside various optimisations and condensing of automation script files.

This small update in version 0.2.1 included a minor fix that resolved an issue with the Python parsing script where trying to parse both Liboqs and OQS-Provider results caused an error. This bug was sadly overlooked, and is now addressed in this minor release.

### Features
The project provides automation for:

- Compiling and configuration of the OQS, ARM PMU, and OpenSSL dependency libraries.

- Gathering PQC computational performance data, including CPU and memory usage metrics using the Liboqs library.

- Gathering Networking performance data for the integration of PQC schemes in the TLS 1.3  protocol by utilising the OpenSSL 3.2.1 and OQS-Provider libraries.

- Coordinated testing of PQC TLS handshakes using either the loopback interface or a physical network connection between a server and client device.

- Parsing of the PQC performance data, where data from multiple machines can be parsed, averaged, and then compared against each other.

## Change Log
As version 0.2.1 contains only one minor change to the code, to address a serious bug, the information on the changes in v0.2.0 compared to v0.1.0 are included here as well for reference. Future releases will return to a normal changelog format.

### Version 0.2.0
A list of the key changes in this release are as follows:

- [Refactored Liboqs auto testing scripts into single script and set Liboqs build to use custom OpenSSL-3.2.1](https://github.com/crt26/pqc-evaluation-tools/commit/9463a97846855ad9cf8bf64883c6717586b3a489)

- [Update to APT packages dependencies](https://github.com/crt26/pqc-evaluation-tools/commit/2c9e0f15154c4b4b3dbf83fd866e150937a55018)

- [TLS handshake tests refactored for PQC testing using OQS-Provider and OpenSSL 3.2.1](https://github.com/crt26/pqc-evaluation-tools/commit/0f5289a3a110f76a6ceca6238ebf2e384f724145)

- [TLS handshake tests refactored for classic algorithm testing using OQS-Provider and OpenSSL 3.2.1](https://github.com/crt26/pqc-evaluation-tools/commit/785b0ec33ca5bd141fe8fe48f8ecd3abcde629a1)

- [TLS speed tests refactored for testing using OQS-Provider and OpenSSL 3.2.1](https://github.com/crt26/pqc-evaluation-tools/commit/d06ee43728563d6a8b1a3e8a128f1b7c71a89897)

- [Added support for the testing and parsing of Hybrid-PQC algorithms when integrated into TLS](https://github.com/crt26/pqc-evaluation-tools/commit/a2f78d2f445c2d070ec66efc3e1d99a7f7a275ac)

- [Optimisation of Python Parsing Scripts](https://github.com/crt26/pqc-evaluation-tools/commit/6b4e692b8083f391d181087f500b3389ffb007d8)

- [Added backwards comparability in parsing scripts for older versions of Python](https://github.com/crt26/pqc-evaluation-tools/commit/1979e9fcb0b000024f460cd5b07a0ca5583c1661)

- [Added exception handling to account for missing Falcon memory metrics data on ARM devices](https://github.com/crt26/pqc-evaluation-tools/commit/cfc529fa75c96be1a57dcde18b2ea02012e5530c)

- [Overall Improvements to Code Formatting and Commenting](https://github.com/crt26/pqc-evaluation-tools/commit/e08aeaf0673741200c931538899137e95afa30be)

- [Added support for dynamically getting what algorithms are supported by the OQS libraries](https://github.com/crt26/pqc-evaluation-tools/commit/f81d25ff23f8cfa13df69ae5608d45bb435a0d6e)

- [Added safe-setup functionality to main setup script to allow for a fallback to the last tested OQS libraries](https://github.com/crt26/pqc-evaluation-tools/commit/6114717f1a967c7a7ca8d95f6f7a7ce94683425e)

- [Resolved Issue where users had to be in the same directory when executing a script in order for it to function](https://github.com/crt26/pqc-evaluation-tools/commit/fde7fd0c6836f5ee63492b68fa8f2d26d6cfb57f)


A full list of the changes made can viewed here:

**Full Changelog**: https://github.com/crt26/pqc-evaluation-tools/compare/v0.1.0-alpha...v0.2.0

### Version 0.2.1
- [Resolved bug where parsing both liboqs and oqs-provider results failed](https://github.com/crt26/pqc-evaluation-tools/commit/a5ef98a0a1358b8b8367903b83c07aebef1e1ece)

## Known Issues

- Manual copying of generated certificate and private key files for the TLS performance benchmarks required.
  
- Limited support for system architectures and operating systems.
  
- Issue with gathering full memory usage metrics for the Falcon Algorithm on ARM devices.

## Important Notes
 - This is an early version of the project, functionality is limited to debian based operating systems.
  
- Activating the automated tools will delete all results currently stored in the up-results directory. To retain previous results, these should be moved to another location prior to re-running the automated test tool.

We look forward to your feedback and contributions to this project!
