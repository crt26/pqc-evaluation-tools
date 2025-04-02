# Release v0.3..
Welcome to the version 0.3.0 release of the PQC-Evaluation-Tools project!

##  Release Overview
The version 0.3.0 release of the PQC-Evaluation-Tools suite delivers key updates focused on compatibility, stability, and usability. It adds support for the latest version of the OQS libraries and has been upgraded to use the latest version of OpenSSL (version 3.4.1).

Automation has been refined with fixes to control signalling, improved handling of TLS benchmarking ports, and more robust detection of port conflicts. The suite now supports older Python versions, and script usability has been enhanced through clearer naming and new help flags.

TLS speed benchmarking is now more stable, resolving issues caused by control signal timing and newer versions of the OQS-Provider library to break the OpenSSL `s_speed` tool when using all its supported algorithms. The release also includes an updated generate.yml for OQS-Provider, along with documentation improvements and general codebase clean-up.

These changes make the toolset more flexible and reliable for evaluating PQC performance, particularly in TLS-based deployments.

## Project Features
The project provides automation for:

- Compiling and configuration of the OQS, ARM PMU, and OpenSSL dependency libraries.

- Gathering PQC computational performance data, including CPU and memory usage metrics using the Liboqs library.

- Gathering Networking performance data for the integration of PQC schemes in the TLS 1.3  protocol by utilising the OpenSSL 3.4.1 and OQS-Provider libraries.

- Coordinated testing of PQC TLS handshakes using either the loopback interface or a physical network connection between a server and client device.

- Parsing of the PQC performance data, where data from multiple machines can be parsed, averaged, and then compared against each other.

## Change Log
* Verify project support for liboqs version 0.12.0 in [#9](https://github.com/crt26/pqc-evaluation-tools/pull/9)
* Update OQS-Provider Script and Variable Naming in [#10](https://github.com/crt26/pqc-evaluation-tools/pull/10)
* Upgrade OpenSSL Dependency to Version 3.4.0 in [#11](https://github.com/crt26/pqc-evaluation-tools/pull/11)
* Fix Control Signalling Issue in Automated TLS Benchmarking Scripts in [#13](https://github.com/crt26/pqc-evaluation-tools/pull/13)
* Add Support for Older Versions of Python in [#17](https://github.com/crt26/pqc-evaluation-tools/pull/17)
* Upgrade OpenSSL Dependency to Security Patch Version 3.4.1 in [#19](https://github.com/crt26/pqc-evaluation-tools/pull/19)
* Make TLS Benchmarking Ports Configurable and Improve Conflict Handling in [#20](https://github.com/crt26/pqc-evaluation-tools/pull/20)
* Update Modified OQS-Provider generate.yml File in [#22](https://github.com/crt26/pqc-evaluation-tools/pull/22)
* Fix False Positives in Port Usage Checks & Relocate Default TLS Benchmarking Ports in [#24](https://github.com/crt26/pqc-evaluation-tools/pull/24)
* Fix TLS Speed Benchmark Failure Caused by Excessive Algorithm Loading in [#26](https://github.com/crt26/pqc-evaluation-tools/pull/26)
* Add Configurable Control Signal Sleep Time to Automated TLS Testing Scripts in [#29](https://github.com/crt26/pqc-evaluation-tools/pull/29)
* Add support for help Flags in Project Scripts in [#32](https://github.com/crt26/pqc-evaluation-tools/pull/32)
* Update and Improve Documentation and Clean Codebase in [#33](https://github.com/crt26/pqc-evaluation-tools/pull/33)

**Full Changelog**: https://github.com/crt26/pqc-evaluation-tools/compare/v0.2.1...v0.3.0

## Important Notes

 -  Functionality is limited to Debian-based operating systems.

 -  If issues still occur with the automated TLS performance test control signalling, information on increasing the signal sleep delay can be seen in the **Advanced Testing Customisation** section of the [TLS Performance Testing Instructions](docs/testing-tools-usage/oqsprovider-performance-testing.md) documentation file.
  
## Future Development
For details on the project's development and upcoming features, see the project's GitHub Projects page:

[PQC-Evaluation-Tools Project Page](https://github.com/users/crt26/projects/2)


We look forward to your feedback and contributions to this project!
