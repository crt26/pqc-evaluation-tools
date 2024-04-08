# PQC Evaluation Tools <!-- omit from toc -->

## Notice:
This is the **development branch**, it may not be in a fully functioning state and documentation may still need updated. The checkboxes below indicates whether the current development version is in a basic functioning state and if the documentation is accurate for its current functionality. Regardless please keep this in mind and use the main branch if possible, thank you.

- [ ] Functioning State
- [ ] Up to date documentation

## Contents <!-- omit from toc --> 
- [Notice:](#notice)
- [Overview](#overview)
- [Supported Hardware](#supported-hardware)
- [Installation Instructions](#installation-instructions)
- [Automated Testing Tools](#automated-testing-tools)
  - [Tools Description](#tools-description)
  - [Liboqs Performance Testing](#liboqs-performance-testing)
  - [OQS-OpenSSL Performance Testing](#oqs-openssl-performance-testing)
  - [Testing Output Files](#testing-output-files)
- [Parsing Test Results](#parsing-test-results)
  - [Parsing Overview](#parsing-overview)
  - [Parsed Results Output](#parsed-results-output)
  - [Graph Generation](#graph-generation)
- [Repository Structure](#repository-structure)
- [Helpful Documentation Links](#helpful-documentation-links)
- [License](#license)
- [Acknowledgements](#acknowledgements)


## Overview

**(Pre-Release Version 0.1.0-Alpha)**

Post-Quantum Cryptography (PQC) is an expanding field which aims to address the security concerns that quantum computers will bring to current cryptographic technologies. Numerous PQC schemes have been proposed to help combat this concern, with each offering differing solutions. 

This repository provides tools that will simplify the process for the gathering and parsing of PQC computational performance data. It includes scripts that will automate the building process, the testing process, and the result parsing process. The final output from these tools is CSV files, containing performance metrics alongside metric averages that can be further used for graph generation. Jupyter notebook code is also contained in the library, for data visualisation. For more information on the tools, please refer to the [Repository Structure](#repository-structure) section.

## Supported Hardware
The automated testing tool is currently only supported on the following devices:

- x86 Debian Based Linux Machines
- ARMv8 Raspberry Pis using a 64-bit Operating System

> Notice: As this is a early release version of the testing suites, the supported hardware is currently limited. However, future versions will address this issue and allow for support on a wider range of architectures and operating systems.


## Installation Instructions

Clone the current stable version:
```
git clone -b main https://github.com/crt26/pqc-eval-tools.git
```

Move into the cloned repository directory and execute the setup script:
```
cd pqc-eval-tools
./setup
```

You may need to change the permissions of the setup script, if that is the case, the setup can be done using the following commands:
```
chmod +x setup.sh
./setup.sh
```

#### Select which OQS benchmarking libraries should be setup:
When executing the setup script, you will be presented with three options:

1. Build only the Liboqs library (used for only testing PQC performance)

2. Build only the OQS-OpenSSL library (user for only testing PQC TLS performance)

3. Build both the Liboqs and OQS-OpenSSL library (used for testing both PQC performance and PQC in TLS performance)

Based on the option you chose you may be presented with a further option which is to select which version of the Liboqs library is used for PQC performance testing, this will not effect the version of Liboqs which is used with the OQS-OpenSSL testing tools. This options for versions are as follows:

1. Liboqs version 0.7.2
2. Liboqs version 0.8

Once all of the relevant options have been selected, the setup script will download, configure and build each of the libraries. Alongside, optimizing the builds for the current systems by automatically passing the relevant build parameters.

## Automated Testing Tools

### Tools Description
There are two sets of automated testing that can be done using these tools:

- PQC performance benchmarking using Liboqs
- PQC integration into TLS performance benchmarking using OQS-OpenSSL

The testing tools can be found within the `test-scripts` directory and are fully automated. The tools allow multiple machines to be tested, with results being assigned a number set at the beginning of the test. The testing scripts are as follows:

### Liboqs Performance Testing

This script automates the CPU and memory performance benchmarking of various PQC algorithms included in the Liboqs library. It generates and records comprehensive metrics which can help in analysing the performance of these algorithms. 

The test script can be executed using the following command:
```
./full-Liboqs-test.sh
```

#### Detailed usage instructions can be found using the following link:

[Liboqs Performance Automated Testing Instructions](docs/testing-tools-documentation/liboqs-performance-testing.md)

### OQS-OpenSSL Performance Testing

This script is focused on benchmarking the performance of PQC algorithms when integrated within the OpenSSL (1.1.1) library via OQS. The script firstly can test the computational efficiency of the PQC algorithms when integrated into the OpenSSL library. Alongside, how PQC algorithms perform when integrated into the TLS protocol by measuring empty TLS handshake performance. Furthermore, metrics for how classic algorithms perform when conducting the TLS handshake to gather data which can be used as a baseline to compare the PQC metrics against.   

The testing tool allows for tests to be conducted on a single machine or using two machine connected via a physical network. It should be noted that when using two physical machines the complexity of setup increases.However, regardless of which scenario, the process requires more additional steps then the Liboqs testing.

#### Detailed usage instructions can be found using the following link:

[PQC TLS Performance Automated Testing Instructions](docs/testing-tools-documentation/tls-performance-testing.md)


### Testing Output Files
After selecting the desired testing script, the performance benchmarks will be performed and the unparsed results will be stored in the newly created ``up-results`` directory within the code's root directory. Liboqs unparsed results will be stored in the `up-results/Liboqs/machine-x`* directory. The PQC TLS test results will be stored in the `up-results/Liboqs/machine-x`* directory.

**The machine number assigned to the test*


> **PLEASE NOTE** - Each time the automated tools are activated, all results currently stored in the up-results directory will be deleted. So please move previous results if you intended to execute the automated test tool again.


## Parsing Test Results

### Parsing Overview

The results from the automated tests can be transformed into workable CSV files using the `parse_results.py` script located in the `result-processing/parsing-scripts` directory. Options are provided to parse the Liboqs results, the OQS-OpenSSL results, or both.

The script requires the test parameters used during the benchmarking, including the number of runs and number of machines tested, if multiple machine results have been stored within the `up-results` directory.

> **PLEASE NOTE:** - The parsing script is supported only on machines with `Python 3.10 and above`. For older versions of Python, results can still be parsed using individual scripts. Instructions are provided below.

### Parsing using Python 3.10 and Above <!-- omit from toc --> 

The parsing process, unlike the testing scripts, can be executed on both Linux and Windows machines. If you're parsing results from multiple machines, make sure all results are present in the `up-results` directory. Execute the parsing script with the following command:

```
python parse_results.py
```

### Parsing using Python 3.9 and Below <!-- omit from toc --> 
For machines running an older version of Python, some features within the parse_results.py may not be supported. In this case, results can be manually parsed by executing the relevant script for the desired type of results to be parsed.

**Liboqs Results Parsing:**
```
python liboqs_parse.py
```

**OQS-OpenSSL Results Parsing**
```
python oqs_openssl_parse.py
```

### Parsed Results Output
At the end of the process, the results will be stored within the newly created **results** directory which can be found in the results folder at the root of the repository. Averages for the results will also be calculated during the parsing process and the average files for the respective test type can be found within the same results directory.

### Graph Generation
Currently the code for automatically is under development and will be included in later versions of the testing suite. However, the results files outputted from the parsing scripts can be used with Microsoft Excel, Python, R-Studio etc. for the creation of graphs. An example Jupyter Notebook, illustrating how this can be done, is included with this version and can be found in the  `result-processing/graph-generators` directory within the code's root directory.

Until this feature is included within this project, helpful links for data visualisation can be found below:

- [Visualising Data with Python](https://www.geeksforgeeks.org/data-visualization-with-python/)
- [Data Visualisation with Python Pandas](https://realpython.com/pandas-plot-python/)
- [Data Visualisation with R](https://www.dataquest.io/blog/data-visualization-in-r-with-ggplot2-a-beginner-tutorial/)
- [Microsoft Excel Chart Creation](https://support.microsoft.com/en-us/office/create-a-chart-from-start-to-finish-0baf399e-dd61-4e18-8a73-b3fd5d5680c2)

## Repository Structure
The pqc-eval-tools repository is organized as follows:

```
pqc-eval-tools/
│
├── alg-lists/
│
├── build-scripts/
│
├── modded-liboqs-files/
│
├── result-processing/
│   ├── graph-generators/
│   └── parsing-scripts/
│
└── test-scripts/

```

#### Directory Description

- alg-lists: Contains various text files which list the quantum algorithms used by the scripts within the project.

- build-scripts: Contains scripts used for building and compiling the project.

- modded-Liboqs-files: Contains Liboqs files that have been modified for the purpose of this project.

- result-processing: Contains scripts that are used for processing and analysing the results. It has two subdirectories:
  
  - graph-generators: Contains scripts or files used for generating graphical representations of the results.
  
  - parsing-scripts: Contains scripts used for parsing the result data.
  
- test-scripts: Contains scripts that are used for testing various components of the project.

## Helpful Documentation Links
- [Liboqs Webpage](https://openquantumsafe.org/Liboqs/)
- [Liboqs GitHub Page](https://github.com/open-quantum-safe/Liboqs)
- [OQS-OpenSSL Webpage](https://openquantumsafe.org/applications/tls.html#oqs-openssl)
- [OQS-OpenSSL GitHub Page](https://github.com/open-quantum-safe/openssl)
- [Latest Liboqs Release Notes](https://github.com/open-quantum-safe/Liboqs/releases/tag/0.8.0)
- [Latest OQS-OpenSSL Release Notes](https://github.com/open-quantum-safe/openssl/releases/tag/OQS-OpenSSL-1_1_1-stable-snapshot-2023-07)
- [OpenSSL(1.1.1) Documentation](https://www.openssl.org/docs/man1.1.1/)
- [TLS 1.3 RFC 8446](https://www.rfc-editor.org/rfc/rfc8446)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE)

## Acknowledgements
This project depends on:

1. [Liboqs](https://github.com/open-quantum-safe/Liboqs) - This project includes modified versions of files from the `Liboqs` project. These modified files are subject to the `Liboqs` MIT license, which can be found at the top of each modified file.
2. [oqs-openssl](https://github.com/open-quantum-safe/openssl) - This project also relies on a fork of the `oqs-openssl` project which includes OpenSSL. The forked `oqs-openssl` repository can be found here: [forked oqs-openssl](https://github.com/crt26/openssl). The OpenSSL toolkit in `oqs-openssl` is dual-licensed under both the OpenSSL License and the original SSLeay license. Refer to the LICENSE in the [oqs-openssl repository](https://github.com/open-quantum-safe/openssl) for full license details.
3. [pqax](https://github.com/mupq/pqax/tree/main) - This project uses the pqax library to enable arm PMU on Raspberry Pi devices. The pqax library is licensed under the Creative Commons Zero v1.0 Universal license, which dedicates the work to the public domain.
