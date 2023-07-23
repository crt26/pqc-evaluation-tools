# Release v0.1.0-alpha
Welcome to the first pre-release of the PQC Evaluation Tools Project!

## Features
- Automated PQC performance benchmarking using Liboqs library.
  
- Automated PQC integration into TLS performance benchmarking using OQS-OpenSSL library.

- Parsing scripts to transform raw benchmark data into workable CSV files.
  
- Automated setup and build scripts for both Liboqs and OQS-OpenSSL libraries.

- Supports benchmarking on x86 Linux devices and Raspberry Pi's.

## Bug Fixes
This being the first pre-release, there are no bug fixes relative to a previous version.

## Known Issues
- Automated graph generation is currently under development and will be included in future releases.

- Manual copying of generated certificate and private key files for the TLS performance benchmarks required.
  
- Limited support for system architectures and operating systems
  
- Limited documentation

## Important Notes
 - This is an early version of the project, functionality is limited to x86 Linux devices and Raspberry Pis. However, future updates will address this issue.
  
- Activating the automated tools will delete all results currently stored in the up-results directory. To retain previous results, these should be moved to another location prior to re-running the automated test tool.

We look forward to your feedback and contributions to this project!