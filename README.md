# PQC Evaluation Tools <!-- omit from toc --> 

## Notice: <!-- omit from toc --> 
This is the **development branch**, it may not be in a fully functioning state and documentation may still need updated. The checkboxes below indicates whether the current development version is in a basic functioning state and if the documentation is accurate for its current functionality. Regardless please keep this in mind and use the main branch if possible, thank you.

- [x] Functioning State*
- [x] Up to date documentation

> *Dev branch Notice: Current functioning state works for both x86 and ARM machines. However, on ARM devices, memory profiling for Falcon algorithm variations is non-functioning. Please refer to [bug-report-on-liboqs-repo](https://github.com/open-quantum-safe/liboqs/issues/1761) for more details. Work is underway to resolve this issue but for now the repository has methods in place to account for this. Automated testing and parsing scripts can still be used to gather performance metrics for all other algorithms on ARM systems. 


## Current Development Branch Tasks <!-- omit from toc --> 

- [x] Update [alg-lists](alg-lists) files to include the latest version of supported algorithms in Liboqs and OQS-OpenSSL-Provider
- [x] Update [oqsssl-generate-keys](scripts/test-scripts/oqsssl-generate-keys.sh) to use current supported algorithms and steps for new OQS-OpenSSL-Provider PQC key generation
- [x] Update [oqsssl-generate-keys](scripts/test-scripts/oqsssl-generate-keys.sh) storage method for generated keys to better suit new directory structure
- [x] Update and refine all automated testing scripts for Liboqs machine-only algorithm performance testing into one script ([full-liboqs-test](scripts/test-scripts/full-liboqs-test.sh)) to use current supported algorithms and new repository directory structure
- [x] Update [oqsssl-generate-keys.sh](scripts/test-scripts/oqsssl-generate-keys.sh) to use current supported algorithms in Liboqs and OQS-OpenSSL-Provider and key generation methods in OpenSSL-3.2.1
- [x] Determine possibility of using s_time tls performance testing tool with OQS-Provider and if not possible create new/modify automated testing scripts using s_server and s_client tools to gather tls performance metrics (parsing scripts will need to be modified to handle this)
- [x] Update [setup.sh](setup.sh) and [oqsssl-generate-keys](scripts/test-scripts/oqsssl-generate-keys.sh) to handle changes to the openssl.conf file during and after setup, as the final conf file for testing will have changes that interfere with the key generation process. A dynamic change to the openssl.conf file will be required for both tasks.
- [x] Update [full-pqc-tls-test.sh](scripts/test-scripts/full-pqc-tls-test.sh) to account for changes in directory structure and OQS-OpenSSL-Provider tools
- [x] Update all automated testing scripts to use a more refined and efficient method for storing result data compared to current up-results method
- [x] Update documentation to reflect changes to repository functionality and structure
- [x] Integrate Hybrid algorithmic testing to OQS-OpenSSL-Provider scripts
- [x] Integrate Hybrid test handling in parsing scripts
- [ ] Resolve issue with scripts being required to be executed from only their stored directory
- [ ] Resolve issues with testing on ARMv8 devices [bug-report-on-liboqs-repo](https://github.com/open-quantum-safe/liboqs/issues/1761)
- [ ] Add functionality for automatically getting supported algorithms for both Liboqs and OQS-Provider to improve scalability. 
- [ ] Add better handling for differentiating between different ARM devices in setup script. 
- [ ] Improve script exception handling. 
- [ ] Prepare for merge to main branch with newer version
## Contents <!-- omit from toc --> 
- [Overview](#overview)
- [Supported Hardware](#supported-hardware)
- [Installation Instructions](#installation-instructions)
- [Automated Testing Tools](#automated-testing-tools)
  - [Tools Description](#tools-description)
  - [Liboqs Performance Testing](#liboqs-performance-testing)
  - [OQS-Provider Performance Testing](#oqs-provider-performance-testing)
  - [Testing Output Files](#testing-output-files)
- [Parsing Test Results](#parsing-test-results)
  - [Parsing Overview](#parsing-overview)
  - [Parsing Script Usage](#parsing-script-usage)
  - [Parsed Results Output](#parsed-results-output)
  - [Graph Generation](#graph-generation)
- [Utility Scripts](#utility-scripts)
- [Repository Structure](#repository-structure)
- [Helpful Documentation Links](#helpful-documentation-links)
- [License](#license)
- [Acknowledgements](#acknowledgements)


## Overview

**Version 0.2.0**

Post-Quantum Cryptography (PQC) is an expanding field which aims to address the security concerns that quantum computers will bring to current cryptographic technologies. Numerous PQC schemes have been proposed to help combat this concern, with each offering differing solutions. 

This repository provides tools that will simplify the process for the gathering and parsing of PQC computational performance data. It includes scripts that will automate the building process, the testing process, and the result parsing process. The final output from these tools is CSV files, containing performance metrics alongside metric averages that can be further used for graph generation. For more information on the tools, please refer to the [Repository Structure](#repository-structure) section.

At the current moment, the repository provides automation in PQC performance testing by integrating tools created by the [Open Quantum Safe](https://openquantumsafe.org/) project using their **Liboqs** and **OQS-Provider libraries** into performance evaliation scripts. Furthermore, it provides an automated and robust way in which to gather network performance testing using physical networks. Going forward, this project aims to incorporate other PQC libraries present in the field, alongside performance testing of other cryptographic systems such as homomorphic encryption. The project aims to provide a cross-platform method of evaluating these systems on multiple systems ranging from standard desktop devices to IoT devices.

The testing scripts allow for the evaluation of all algorithms supported by Liboqs version 0.10.0 alongside the evaluation of both PQC only and PQC-Hybrid schemes in TLS exchanges to allow for an extensive assessment of the performance of PQC solutions on the system the repository is ran on. 

> Notice: At the current moment, due to how directory paths variables are handled by the scripts in the project, all scripts must be executed from the directory that stored in. This issue will be addressed in following version of the project.

## Supported Hardware
The automated testing tool is currently only supported on the following devices:

- x86 Linux Machines using Debian based distros
- ARM devices using a 64-bit Operating System

> Notice: Current functioning state works for both x86 and ARM machines. However, on ARM devices, memory profiling for Falcon algorithm variations is non-functioning. Please refer to [bug-report-on-liboqs-repo](https://github.com/open-quantum-safe/liboqs/issues/1761) for more details. Work is underway to resolve this issue but for now the repository has methods in place to account for this. Automated testing and parsing scripts can still be used to gather performance metrics for all other algorithms on ARM systems. 


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

1. Build only the liboqs library (used for only testing PQC performance)

2. Build both the liboqs and OQS-Provider libraries (used for testing both PQC performance and PQC in TLS performance) 

3. Build the OQS-Provider Library after a previous install of Liboqs


The setup script will also handle the building of [OpenSSL 3.2.1](https://www.openssl.org/source/) within the pqc-eval-tools lib directory as this is required to utilise the OpenSSL provider functionality provided by OQS-Provider. This will be a separate build from the systems default OpenSSL installation and will not replace or interfere with those binaries.

Once all of the relevant options have been selected, the setup script will download, configure and build each of the libraries. Alongside, optimizing the builds for the current systems by automatically passing the relevant build parameters.

## Automated Testing Tools

### Tools Description
There are two sets of automated testing that can be done using these tools:

- PQC performance benchmarking using Liboqs
- PQC integration into TLS performance benchmarking using OQS-Provider

The testing tools can be found within the `scripts/test-scripts` directory and are fully automated. The tools allow multiple machines to be tested, with results being assigned a number set at the beginning of the test. The testing scripts are as follows:

### Liboqs Performance Testing

This script automates the CPU and memory performance benchmarking of various PQC algorithms included in the liboqs library. It generates and records comprehensive metrics which can help in analysing the performance of these algorithms. 

The test script can be executed using the following command:
```
./full-liboqs-test.sh
```

#### Detailed usage instructions can be found using the following link:

[liboqs Performance Automated Testing Instructions](docs/testing-tools-documentation/liboqs-performance-testing.md)

### OQS-Provider Performance Testing

This script is focused on benchmarking the performance of PQC and PQC-Hybrid algorithms when integrated within the OpenSSL (3.2.1) library via the OQS-Provider. The script firstly can test the computational efficiency of the PQC algorithms when integrated into the OpenSSL library. Alongside, how PQC/PQC-Hybrid algorithms perform when integrated into the TLS protocol by measuring empty TLS handshake performance. Furthermore, metrics for how classic algorithms perform when conducting the TLS handshake to gather data which can be used as a baseline to compare the PQC metrics against.   

The testing tool allows for tests to be conducted on a single machine or using two machine connected via a physical network. It should be noted that when using two physical machines the complexity of setup increases. However, regardless of which scenario, the process requires more additional steps then the liboqs testing.

#### Detailed usage instructions can be found using the following link:

[PQC TLS Performance Automated Testing Instructions](docs/testing-tools-documentation/tls-performance-testing.md)


### Testing Output Files
After selecting the desired testing script, the performance benchmarks will be performed and the unparsed results will be stored in the newly created ``test-data/up-results`` directory. Liboqs unparsed results will be stored in the `test-data/up-results/liboqs/machine-x`* directory. The PQC TLS test results will be stored in the `test-data/up-results/oqs-openssl/machine-x`* directory.

**The Machine-ID number assigned to the test*


## Parsing Test Results

### Parsing Overview

The results from the automated tests can be transformed into workable CSV files using the `parse_results.py` script located in the `scripts/parsing-scripts` directory. Options are provided to parse the liboqs results, the OQS-Provider results, or both.

The script requires the test parameters used during the benchmarking, including the number of runs and number of machines tested, if multiple machine results have been stored within the `test-data/up-results` directory. Please make sure all up-results are present in this directory that you wish to be parsed before executing the `parse_results.py` script.


### Parsing Script Usage

The parsing process, unlike the testing scripts, can be executed on both Linux and Windows machines. If you're parsing results from multiple machines, make sure all results are present in the `up-results` directory. Execute the parsing script with the following commands depending on the default Python command alias:

```
python3 parse_results.py
```


### Parsed Results Output
At the end of the process, the results will be stored within the newly created **results** directory which can be found in the results folder at `test-data/results`. Averages for the results will also be calculated during the parsing process and the average files for the respective test type can be found within the same results directory.

### Graph Generation
The results files outputted from the parsing scripts can be used with Microsoft Excel, Python, R-Studio etc. for the creation of graphs, helpful links for data visualisation can be found below:

- [Visualising Data with Python](https://www.geeksforgeeks.org/data-visualization-with-python/)
- [Data Visualisation with Python Pandas](https://realpython.com/pandas-plot-python/)
- [Data Visualisation with R](https://www.dataquest.io/blog/data-visualization-in-r-with-ggplot2-a-beginner-tutorial/)
- [Microsoft Excel Chart Creation](https://support.microsoft.com/en-us/office/create-a-chart-from-start-to-finish-0baf399e-dd61-4e18-8a73-b3fd5d5680c2)


## Utility Scripts
The utility scripts provided may be useful when developing or testing using the various scripts contained in the repository or when setting up performance testing environments. More refined and encompassing utility scripts will be added as the project progresses. All utility scripts bar the `uninstall.sh` script can be found in the `scripts/utility-scripts` directory.

The current set of utility scripts includes:

- **uninstall.sh** - A script for automatically removing certain all libraries installed depending on the options supplied.

- **clear-test-data.sh** - This script will remove all results and generated keys that are currently being stored. This can be useful in development of the automated testing tools or to clear old results quickly.
  
- **configure-openssl-cnf.sh** - This script can change the configurations added to the OpenSSL 3.2.1 configuration file by commenting or uncommenting the lines which set what default groups OpenSSL uses. This is needed to allow both the `oqsssl-generate-keys.sh` and the TLS performance testing scripts to operate correctly. This script is mainly used by the automated scripts, however it can be called manually using the following commands:

**configure-openssl-cnf.sh - Comment out Default Group Configurations:**
```
./configure-openssl-cnf.sh 0
```

**configure-openssl-cnf.sh - Uncomment out Default Group Configurations:**
```
./configure-openssl-cnf.sh 1
```

> Notice: As the `configure-openssl-cnf.sh` script is intended mainly to be used by the automated testing scripts, please take caution when calling the script manually. This is due to how the script anticipates the state of the configuration file. If calling manually ensure to verify the openssl.cnf file for any double comments or other misconfigurations.

## Repository Structure
The repository will contain default directories present when cloned and during operation will create various directories required for its functionality. Directories created by the scripts shown in the following directory structure will be marked with a "*".


The pqc-eval-tools repository is organized as follows:

```
pqc-eval-tools/
│
├── docs
│   └── testing-tools-documentation
│
├── lib*
│
├── modded-lib-files
│
├── scripts
│   ├── parsing-scripts
│   ├── utility-scripts
│   └── test-scripts
│
└── test-data
    ├── alg-lists
    ├── results*
    └── up-results*
```

#### Directory Description

- **docs**: Contains various documentation files related to the repository and its functionality.

- **lib***: This directory will contain the various libraries which are used by the project to conduct the performance testing after the setup operations have been performed. This will includes libraries provided by the OQS Project, OpenSSL and Pqax.

- **modded-lib-files**: Contains OQS project files that have been modified for the purpose of this repositories functionality.

- **test-data**: Contains various sub-directories for the data required to operate the automated testing scripts and is where the results directories will be generated and stored.

  - **alg-lists**: Contains various text files which list the quantum algorithms used by the scripts within the project.
  - **results***: Contains the parsed results created by the Python parsing scripts.
  - **up-results*** Contains the 

- **scripts**: Contains the various sub-directories which houses the testing, parsing, and utility scripts. 
  
  - parsing-scripts: Contains scripts used for parsing the result data.
  
  - test-scripts: Contains scripts that are used for testing various components of the project.

  - utility-scripts: Contains the utility scripts used by the user and the automated testing scripts. 
  


## Helpful Documentation Links
- [liboqs Webpage](https://openquantumsafe.org/liboqs/)
- [liboqs GitHub Page](https://github.com/open-quantum-safe/liboqs)
- [OQS-Provider Webpage](https://openquantumsafe.org/applications/tls.html#oqs-openssl-provider)
- [OQS-Provider GitHub Page](https://github.com/open-quantum-safe/oqs-provider)
- [Latest liboqs Release Notes](https://github.com/open-quantum-safe/liboqs/blob/main/RELEASE.md)
- [Latest OQS-Provider Release Notes](https://github.com/open-quantum-safe/oqs-provider/blob/main/RELEASE.md)
- [OpenSSL(3.2.1) Documentation](https://www.openssl.org/docs/man3.2/index.html)
- [TLS 1.3 RFC 8446](https://www.rfc-editor.org/rfc/rfc8446)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE)

## Acknowledgements
This project depends on:

1. [Liboqs](https://github.com/open-quantum-safe/liboqs) - This project includes modified versions of files from the `liboqs` project. These modified files are subject to the `liboqs` MIT license, which can be found at the top of each modified file.

2. [OQS-Provider](https://github.com/open-quantum-safe/openssl) - This project relies on the OpenSSL provider created by the `OQS-Provider` project. The project is subject to a MIT licence, details of which can be found in the projects repositories root directory. 

3. [OpenSSL](https://github.com/openssl/openssl) - This project utilises the OpenSSL library through its own scripts and the libraries provided by the OQS Project. The OpenSSL project is  under the Apache 2.0 license, details of which can be found in the projects repositories root directory.

4. [pqax](https://github.com/mupq/pqax/tree/main) - This project uses the pqax library to enable arm PMU on Raspberry Pi devices. The pqax library is licensed under the Creative Commons Zero v1.0 Universal license, which dedicates the work to the public domain.
