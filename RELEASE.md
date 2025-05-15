# Version v0.3.1 Release
Welcome to the version 0.3.1 release of the PQC-Evaluation-Tools project!

##  Release Overview
Version 0.3.1 is a maintenance release focused on resolving critical bugs introduced by recent changes in upstream dependencies. It addresses issues affecting algorithm detection, TLS handshake stability, and improves exception handling for computational performance testing on ARM-based systems. Additionally, a licence compliance review was completed to ensure all third-party usage remains properly attributed and documented.

## Project Features
The project provides automation for:

- Compiling and configuration of the OQS, ARM PMU, and OpenSSL dependency libraries.

- Gathering PQC computational performance data, including CPU and memory usage metrics using the Liboqs library.

- Gathering Networking performance data for the integration of PQC schemes in the TLS 1.3  protocol by utilising the OpenSSL 3.4.1 and OQS-Provider libraries.

- Coordinated testing of PQC TLS handshakes using either the loopback interface or a physical network connection between a server and client device.

- Parsing of the PQC performance data, where data from multiple machines can be parsed, averaged, and then compared against each other.

## Change Log  
* Fix automated algorithm detection and TLS handshake failures due to UOV signature size limits in [#44](https://github.com/crt26/pqc-evaluation-tools/pull/44)  
* Fix ARM PMU access loss after reboot on some Raspberry Pi devices in [#45](https://github.com/crt26/pqc-evaluation-tools/pull/45)  
* Fix HQC not being enabled by default in Liboqs builds in [#47](https://github.com/crt26/pqc-evaluation-tools/pull/47)  
* Complete licence compliance review for third-party dependencies in [#51](https://github.com/crt26/pqc-evaluation-tools/pull/51)  

**Full Changelog**: https://github.com/crt26/pqc-evaluation-tools/compare/v0.3.0...v0.3.1

## Important Notes

 -  Functionality is limited to Debian-based operating systems.

 -  If issues still occur with the automated TLS performance test control signalling, information on increasing the signal sleep delay can be seen in the **Advanced Testing Customisation** section of the [TLS Performance Testing Instructions](docs/testing-tools-usage/oqsprovider-performance-testing.md) documentation file.
  
## Future Development
For details on the project's development and upcoming features, see the project's GitHub Projects page:

[PQC-Evaluation-Tools Project Page](https://github.com/users/crt26/projects/2)


We look forward to your feedback and contributions to this project!
