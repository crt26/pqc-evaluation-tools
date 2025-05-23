# PQC Evaluation Tools <!-- omit from toc -->

## Notice: <!-- omit from toc -->
This is the **development branch**, it may not be in a fully functioning state and documentation may still need updated. The checkboxes below indicates whether the current development version is in a basic functioning state and if the documentation is accurate for its current functionality. Regardless please keep this in mind and use the main branch if possible, thank you.

- [x] Functioning State*
- [x] Up to date documentation

### Main Development Branch Task Tracking
For full details on the project's development and the current development task lists, please refer to the repositories Github Projects Page here:

[PQC-Evaluation-Tools Project Page](https://github.com/users/crt26/projects/2)

## Repository Overview <!-- omit from toc -->

### Project Description
This repository provides an automated and comprehensive evaluation framework for benchmarking Post-Quantum Cryptography (PQC) algorithms. It is designed for researchers and developers looking to evaluate the feasibility of integrating PQC into their environments. It simplifies the setup, testing, and parsing of PQC computational and networking performance data across x86 and ARM systems through a series of dedicated automation scripts.

It currently utilises the [Open Quantum Safe (OQS)](https://openquantumsafe.org/) project's `Liboqs` and `OQS-Provider` libraries, alongside PQC implementation available in OpenSSL 3.5.0, with future goals to integrate additional PQC libraries. The framework also provides automated mechanisms for testing PQC TLS handshake performance across physical or virtual networks, providing valuable insight into real-world environment testing. Results are outputted as raw CSV files that can be parsed using the provided Python parsing scripts to provide detailed metrics and averages ready for analysis.

### Supported Automation Functionality
The project provides automation for:

- Compiling and configuring the OQS, ARM PMU, and OpenSSL dependency libraries.

- Collecting PQC computational performance data, including CPU and memory usage metrics, using the Liboqs library.

- Gathering networking performance data for PQC schemes integrated into the TLS 1.3 protocol using the OpenSSL 3.5.0 and the OQS-Provider libraries.

- Coordinated PQC TLS handshake tests run over the loopback interface or across physical networks between a server and client device.

- Parsing performance data from one or more machines, calculating averages, and enabling cross-system comparison.

### Project Development
For details on the project's development and upcoming features, see the project's GitHub Projects page:

[PQC-Evaluation-Tools Project Page](https://github.com/users/crt26/projects/2)

## Contents <!-- omit from toc -->
- [Supported Hardware and Software](#supported-hardware-and-software)
- [Supported Crytpographic Algorithms](#supported-crytpographic-algorithms)
- [Installation Instructions](#installation-instructions)
  - [Cloning the Repository](#cloning-the-repository)
  - [Choosing Installation Mode](#choosing-installation-mode)
  - [Ensuring Root Dir Path Marker is Present](#ensuring-root-dir-path-marker-is-present)
  - [Optional Setup Flags](#optional-setup-flags)
- [Automated Testing Tools](#automated-testing-tools)
  - [Liboqs Performance Testing](#liboqs-performance-testing)
  - [OQS-Provider TLS Performance Testing](#oqs-provider-tls-performance-testing)
  - [Testing Output Files](#testing-output-files)
- [Parsing Test Results](#parsing-test-results)
  - [Parsing Overview](#parsing-overview)
  - [Parsing Script Usage](#parsing-script-usage)
  - [Parsed Results Output](#parsed-results-output)
- [Additional Documentation](#additional-documentation)
  - [Project Wiki Page](#project-wiki-page)
- [Licence](#licence)
- [Acknowledgements](#acknowledgements)

## Supported Hardware and Software

### Compatible Hardware and Operating Systems <!-- omit from toc -->
The automated testing tool is currently only supported in the following environments:

- x86 Linux Machines using a Debian-based operating system
- ARM Linux devices using a 64-bit Debian based Operating System
- Windows systems, if used **only** for parsing raw performance results

### Tested Dependency Libraries <!-- omit from toc -->
This version of the repository has been fully tested with the following library versions:

- Liboqs Version 0.13.0

- OQS Provider Version 0.8.0

- OpenSSL Version 3.5.0

The repository is configured to pull the latest versions of the OQS projects while maintaining the listed OpenSSL version. This ensures support for the most up-to-date algorithms available from the OQS project. The setup process includes handling changes in the OQS libraries and helping maintain compatibility as updates are released.

However, as the OQS libraries are still developing projects, if any major changes have occurred to their code bases, this project's automation scripts may not be able to accommodate this. If this does happen, please report an issue to this repositories GitHub page where it will be addressed as soon as possible. In the meantime, it is possible to change the versions of the OQS libraries used by the benchmarking suite. This is detailed further in the [Installation Instructions](#installation-instructions) section.

## Supported Crytpographic Algorithms
For further information on the classical and PQC algorithms this project provides support for, including information on any exclusions, please refer to the following documentation:

[Supported Algorithms](docs/supported-algorithms.md)

## Installation Instructions
The standard setup process uses the latest versions of the OQS libraries and performs automatic system detection and installation of the benchmarking suite. It supports various installation modes that determine which OQS libraries are downloaded and built, depending on your environment.

The main setup script also provides a `safe-mode` option, which can be used if there are any issues with the latest versions of the OQS libraries. When `safe-mode` is enabled, the script downloads and builds the last tested versions of the OQS libraries that are known to work reliably with this project. For more details on using `safe-mode`, see the [Optional Setup Flags](#optional-setup-flags) section.

The following instructions describe the standard setup process, which is the default and recommended option.

### Cloning the Repository
Clone the current stable version:

```
git clone https://github.com/crt26/pqc-evaluation-tools.git
```

Move into the cloned repository directory and execute the setup script:

```
cd pqc-evaluation-tools
./setup
```

You may need to change the permissions of the setup script; if that is the case, this can be done using the following commands:

```
chmod +x setup.sh
```

### Choosing Installation Mode
When executing the setup script, you will be prompted to select one of the following installation options:

1. **Build only the Liboqs library** – For PQC computational performance testing only.

2. **Build both the Liboqs and OQS-Provider libraries** – For full testing, including PQC performance and PQC TLS benchmarking.

3. **Build only the OQS-Provider library** – For use after a prior Liboqs installation.

The setup script will also build [OpenSSL 3.5.0](https://www.openssl.org/source/) inside the repository’s `lib` directory. This version is required to support the OQS-Provider and is built separately from the system’s default OpenSSL installation. It will not interfere with system-level binaries.

If the installation of the `OQS-Provider` library is selected, the setup script will prompt you to enable two optional features:

- **Enable all disabled signature algorithms** – Includes all digital signature algorithms in the OQS-Provider build that are disabled by default. This ensures the full range of supported algorithms can be tested in the TLS performance benchmarking **†**.

- **Enable KEM encoders** – Adds support for OpenSSL’s optional KEM encoder functionality. The benchmarking suite does not currently use this feature but is available for developers who wish to experiment with it.

Once all the relevant options have been selected, the setup script will download, configure and build each library. It will also tailor the builds for your system architecture by applying appropriate build flags.

> † Enabling all signature algorithms may cause the OpenSSL speed tool to fail due to internal limits in its source code. The setup script attempts to patch this automatically, but you can configure it manually. Please refer to the [Advanced Setup Configuration](docs/advanced-setup-configuration.md) for further details.

### Ensuring Root Dir Path Marker is Present
A hidden file named `.pqc_eval_dir_marker.tmp` is created in the project's root directory during setup. Automation scripts use this marker to reliably identify the root path, which is essential for their correct operation.

When running the setup script, it is vital that this is done from the root of the repository so this file is placed correctly. 

Do **not** delete or rename this file while the project is in a configured state. It will be automatically removed when uninstalling all libraries using the `cleaner.sh` utility script. If the file is removed manually, it can be regenerated by rerunning the setup script or creating it manually.

To verify the file exists, use:

```
ls -la
```

To manually recreate the file, run the following command from the root directory:

```
touch .pqc_eval_dir_marker.tmp
```

### Optional Setup Flags
For advanced setup options, including:
- `safe-mode` for using the last tested versions of the dependency libraries,
- Custom OpenSSL `speed.c` limits, 
- Enabling HQC algorithms in Liboqs
 
Please refer to the [Advanced Setup Configuration Guide](docs/advanced-setup-configuration.md).

## Automated Testing Tools
The repository provides two categories of automated benchmarking:

- **Liboqs Performance Testing** - Used for gathering PQC computational performance data using the Liboqs library.

- **PQC TLS Performance Testing** - Used for gathering PQC TLS 1.3 networking performance benchmarking using PQC implementation available in the OpenSSL 3.5.0 and OQS-Provider libraries.

The testing tools are located in the `scripts/test-scripts` directory and are fully automated. The tools support multi-machine testing, with the option to assign a machine ID when executing the testing scripts.

### Liboqs Performance Testing
This tool benchmarks CPU and memory usage for various PQC algorithms supported by the Liboqs library. It produces detailed performance metrics for each tested algorithm.

For detailed usage instructions, please refer to:

[Automated Liboqs Performance Testing Instructions](docs/testing-tools-usage/liboqs-performance-testing.md)

> **Notice 1:** The HQC KEM algorithms are disabled by default in recent Liboqs versions due to a disclosed IND-CCA2 vulnerability. For benchmarking purposes, the setup process includes an optional flag to enable HQC, accompanied by a user confirmation prompt and warning. For instructions on enabling HQC, see the [Advanced Setup Configuration Guide](docs/advanced-setup-configuration.md), and refer to the [Disclaimer Document](./DISCLAIMER.md) for more information on this issue.

> **Notice 2:** Memory profiling for Falcon algorithm variants is currently non-functional on **ARM** systems due to issues with the scheme and the Valgrind Massif tool. Please see the [bug report](https://github.com/open-quantum-safe/liboqs/issues/1761) for details. Testing and parsing remain fully functional for all other algorithms.

### OQS-Provider TLS Performance Testing
This tool is focused on benchmarking the performance of PQC and Hybrid-PQC algorithms when integrated into TLS 1.3. This is done using the PQC implementations available in OpenSSL 3.5.0 alongside integrating additional PQC schemes into OpenSSL using the OQS-Provider library.

It conducts two types of testing:

- **TLS handshake performance testing** – Measures the performance of PQC and Hybrid-PQC algorithms during TLS 1.3 handshakes.

- **Cryptographic operation benchmarking** – Measures the CPU performance of individual PQC/Hybrid-PQC digital signature and Key Encapsulation Mechanism (KEM) cryptographic operations when integrated within OpenSSL.

Testing can be performed on a single machine or across two machines connected via a physical/virtual network. While the multi-machine setup involves additional configuration, it is fully supported by the automation tools.

For detailed usage instructions, please refer to:

[Automated OQS-Provider TLS Performance Testing Instructions](docs/testing-tools-usage/oqsprovider-performance-testing.md)

### Testing Output Files
After the testing has been completed, unparsed results will be stored in the `test-data/up-results` directory:

- **Liboqs results**: `test-data/up-results/liboqs/machine-x/`

- **OQS-Provider results**: `test-data/up-results/oqs-provider/machine-x/`

Where `machine-x` refers to the machine ID assigned at the beginning of the test. This ID is used to organise output when running tests across multiple machines.

## Parsing Test Results

### Parsing Overview
The results generated from the automated tests can be parsed into structured CSV files using the `parse_results.py` script, located in the `scripts/parsing-scripts` directory. This script provides three methods in which to parse the results:

- Only Liboqs testing data
- Only OQS-Provider TLS testing data
- Both Liboqs and OQS-Provider testing data

If parsing results for multiple machine-IDs, please ensure that all relevant test results are located in the `test-data/up-results` directory before running the script. When executing the script, you will be prompted to enter the testing parameters, such as the number of machines tested and the number of testing runs conducted in each testing category **†**.

If you run the parsing script on a different system or environment from where the `setup.sh` script was executed, ensure the `pandas` Python package is installed. This is the only external dependency required for parsing. You can install it using:

```
pip install pandas
```

> **†** Note: The script currently requires that all machines used for testing ran the same number of test runs in a given testing category (Liboqs/OQS-Provider). If there’s a mismatch, parse each machine’s results separately, then rename and organise the output manually if needed.

### Parsing Script Usage
The parsing script can be executed on both Linux and Windows systems. To run it, use the following command (depending on your system's Python alias):

```
python parse_results.py
```

### Parsed Results Output
Once parsing is complete, the parsed results will be stored in the newly created `test-data/results` directory. This includes CSV files containing the detailed test results and automatically calculated averages for each test category. These files are ready for further analysis or can be imported into graphing tools for visualisation.

Please refer to the [Performance Metrics Guide](docs/performance-metrics-guide.md) for a detailed description of the performance metrics that this project can gather, what they mean, and how these scripts structure the un-parsed and parsed data.

## Additional Documentation

### Internal Project Documentation <!-- omit from toc -->
- [Liboqs Automated Performance Testing](docs/testing-tools-usage/liboqs-performance-testing.md)
- [OQS-Provider Automated Performance Testing](docs/testing-tools-usage/oqsprovider-performance-testing.md)
- [Advanced Setup Configuration](docs/advanced-setup-configuration.md)
- [Supported Algorithms](docs/supported-algorithms.md)
- [Project Scripts](docs/developer-information/project-scripts.md)
- [Repository Structure](docs/developer-information/repository-directory-structure.md)
- [Performance Metrics Guide](docs/performance-metrics-guide.md)
- [Project Disclaimer](./DISCLAIMER.md)

### Project Wiki Page
The information provided in the internal documentation is also available through the project's GitHub Wiki:

[PQC-Evaluation-Tools Wiki](https://github.com/crt26/pqc-evaluation-tools/wiki)

### Helpful External Documentation Links <!-- omit from toc -->
- [Liboqs Webpage](https://openquantumsafe.org/liboqs/)
- [Liboqs GitHub Page](https://github.com/open-quantum-safe/liboqs)
- [OQS-Provider Webpage](https://openquantumsafe.org/applications/tls.html#oqs-openssl-provider)
- [OQS-Provider GitHub Page](https://github.com/open-quantum-safe/oqs-provider)
- [Latest Liboqs Release Notes](https://github.com/open-quantum-safe/liboqs/blob/main/RELEASE.md)
- [Latest OQS-Provider Release Notes](https://github.com/open-quantum-safe/oqs-provider/blob/main/RELEASE.md)
- [OpenSSL(3.5.0) Documentation](https://docs.openssl.org/3.5/)
- [TLS 1.3 RFC 8446](https://www.rfc-editor.org/rfc/rfc8446)

## Licence

This project is licensed under the MIT License – see the [LICENSE](LICENSE) file for details.

## Acknowledgements

This project depends on the following third-party software and libraries:

1. **[Liboqs](https://github.com/open-quantum-safe/liboqs)** – Used to provide standalone implementations of post-quantum key encapsulation mechanisms (KEMs) and digital signature algorithms for computational performance testing. This project includes modified versions of the `test_kem_mem.c` and `test_sig_mem.c` files in order to collect detailed memory usage metrics during benchmarking with minimal terminal output. These modifications remain under the original MIT License, which is noted at the top of each modified file.

2. **[OQS-Provider](https://github.com/open-quantum-safe/oqs-provider)** – Used to integrate post-quantum algorithms from `Liboqs` into OpenSSL via the provider interface, enabling TLS-based performance testing. Modifications include dynamically altering the `generate.yml` template to optionally enable all signature algorithms that are disabled by default. The provider is built locally and dynamically linked into OpenSSL. It is licensed under the MIT License.

3. **[OpenSSL](https://github.com/openssl/openssl)** – Used as the core cryptographic library for TLS testing and benchmarking. This project applies runtime modifications during the build process to increase the hardcoded algorithm limits in `speed.c` (`MAX_KEM_NUM` and `MAX_SIG_NUM`) to support benchmarking of a broader algorithm set, and to append configuration directives to `openssl.cnf` to register and activate the `oqsprovider`. OpenSSL is licensed under the Apache License 2.0.

4. **[pqax](https://github.com/mupq/pqax)** – Used to enable access to the ARM Performance Monitor Unit (PMU) on ARM-based systems such as Raspberry Pi. This allows precise benchmarking of CPU cycles. No modifications are made to the original source code. Pqax is licensed under the Creative Commons Zero v1.0 Universal (CC0) license, placing it in the public domain.

