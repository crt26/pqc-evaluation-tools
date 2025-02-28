# PQC Evaluation Tools <!-- omit from toc --> 

## Notice: <!-- omit from toc --> 
This is the **development branch**, it may not be in a fully functioning state and documentation may still need updated. The checkboxes below indicates whether the current development version is in a basic functioning state and if the documentation is accurate for its current functionality. Regardless please keep this in mind and use the main branch if possible, thank you.

- [x] Functioning State*
- [x] Up to date documentation

<!-- > *Dev branch Notice: Current functioning state works for both x86 and ARM machines. However, on ARM devices, memory profiling for Falcon algorithm variations is non-functioning. Please refer to [bug-report-on-liboqs-repo](https://github.com/open-quantum-safe/liboqs/issues/1761) for more details. Work is underway to resolve this issue but for now the repository has methods in place to account for this. Automated testing and parsing scripts can still be used to gather performance metrics for all other algorithms on ARM systems.  -->

## Main Development Branch Task Tracking
For full details on the project's development and the current development task lists, please refer to the repositories Github Projects Page here:

[PQC-Eval-Tools Project Page](https://github.com/users/crt26/projects/2)


## Repository Overview <!-- omit from toc -->  

### Project Description
Post-Quantum Cryptography (PQC) is an expanding field which aims to address the security concerns that quantum computers will bring to current cryptographic technologies. Numerous PQC schemes have been proposed to help combat this concern, with each offering differing solutions. 

The goal of this repository is to provide tools that will simplify the process for the gathering and parsing of PQC computational and networking performance data. It includes scripts that will automate the building process, the testing process, and the result parsing process. The final output from these tools is CSV files, containing performance metrics alongside metric averages that can be further used for graph generation.

Currently the repository provides automation for PQC performance testing by integrating the PQC libraries created by the [Open Quantum Safe](https://openquantumsafe.org/) project, specifically their **Liboqs** and **OQS-Provider** libraries. This includes automation for gathering computational performance data using the Liboqs library and TLS with PQC integration networking performance data using the OQS-Provider library. Furthermore, an additional benefit this project provides is an automated and robust way in which to gather network performance testing using physical networks, where testing is coordinated between the physical server and client machines.


### Supported Automation Functionality
The project provides automation for:

- Compiling and configuration of the OQS, ARM PMU, and OpenSSL dependency libraries.

- Gathering PQC computational performance data, including **CPU** and **memory usage** metrics using the **Liboqs** library.

- Gathering Networking performance data for the integration of PQC schemes in the **TLS 1.3**  protocol by utilising the **OpenSSL 3.4.1** and **OQS-Provider** libraries.

- Coordinated testing of PQC TLS handshakes using either the loopback interface or a physical network connection between a server and client device.

- Parsing of the PQC performance data, where data from multiple machines can be parsed, averaged, and then compared against each other.


### Future Goals
Going forward, this project aims to incorporate other PQC libraries present in the field, alongside performance testing of other cryptographic systems such as homomorphic encryption. Furthermore, future functionality will include the ability to provide a cross-platform method of evaluating these systems on multiple systems ranging from standard desktop devices to IoT devices.


## Contents <!-- omit from toc --> 
- [Main Development Branch Task Tracking](#main-development-branch-task-tracking)
  - [Project Description](#project-description)
  - [Supported Automation Functionality](#supported-automation-functionality)
  - [Future Goals](#future-goals)
- [Supported Hardware and Software](#supported-hardware-and-software)
- [Installation Instructions](#installation-instructions)
  - [Standard Setup](#standard-setup)
  - [Safe Setup](#safe-setup)
  - [Ensuring Root Dir Path Marker is Present](#ensuring-root-dir-path-marker-is-present)
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
- [Repository Directory Structure](#repository-directory-structure)
  - [Overview](#overview)
  - [Layout and Descriptions](#layout-and-descriptions)
- [Helpful Documentation Links](#helpful-documentation-links)
- [License](#license)
- [Acknowledgements](#acknowledgements)


## Supported Hardware and Software

### Compatible Hardware and Operating Systems <!-- omit from toc --> 
The automated testing tool is currently only supported on the following devices:

- x86 Linux Machines using a Debian based operating system
- ARM Linux devices using a 64-bit Debian based Operating System

### Tested Dependency Software <!-- omit from toc --> 
This version of the repository has been fully tested using the following versions of the dependency libraries:

- Liboqs Version 0.12.0

- OQS Provider Version 0.8.0

- OpenSSL Version 3.4.1

The repository is currently setup to pull the most up to date versions of the OQS projects and maintain use of the listed OpenSSL version above. This is to ensure the latest available algorithms can be tested and evaluated. Handling has been implemented to accommodate for any changes to the algorithms that are supported by the OQS libraries as newer versions are released.

**However, as the OQS libraries are still developing projects, if any major changes have occurred to their code bases and this project's scripts does not accommodate this, please report an issue to this repositories GitHub page.**

The issue will be resolved ASAP and in the meantime, it is possible to change the versions of the OQS libraries used by the benchmarking suite. This is detailed further in the [Installation Instructions](#safe-setup-configuration) section.

By reporting this issue, you would be helping ensure that the tool is fully functioning and able to provide the most up to date PQC performance data for yourself and other researchers who may be utilising this benchmarking suite. Reporting any issues with the latest versions of the OQS libraries will be greatly appreciated :)

> Notice: Current functioning state works for both x86 and ARM machines. However, on ARM devices, memory profiling for Falcon algorithm variations is non-functioning. Please refer to [bug-report-on-liboqs-repo](https://github.com/open-quantum-safe/liboqs/issues/1761) for more details. Work is underway to resolve this issue but for now the repository has methods in place to account for this. Automated testing and parsing scripts can still be used to gather performance metrics for all other algorithms on ARM systems.

## Installation Instructions
To install and configure the benchmarking suite there are two main options, Standard Setup and Safe Setup. This is to allow for the usage of up to date dependency libraries whilst still providing a fallback to the last tested versions of the dependencies in the event of a drastic change to their code base.

### Standard Setup
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

The setup script will also handle the building of [OpenSSL 3.4.1](https://www.openssl.org/source/) within the pqc-eval-tools lib directory as this is required to utilise the OpenSSL provider functionality provided by OQS-Provider. This will be a separate build from the systems default OpenSSL installation and will not replace or interfere with those binaries.

Additionally, if compiling the OQS-Provider library, the setup script will prompt you to enable the optional KEM encoders feature. This feature is supported by OQS-Provider, but this repository does not currently utilize it. However, developers who wish to take advantage of KEM encoders can enable this option during setup.

Once all of the relevant options have been selected, the setup script will download, configure and build each of the libraries. Alongside, optimizing the builds for the current systems by automatically passing the relevant build parameters.

### Safe Setup
If there are issues with this benchmarking suite when using the latest versions of the OQS libraries available, it is possible to perform the setup using the last tested versions of these dependencies. The instructions for installation remain the same, however, when calling the setup.sh script, the `--safe-setup` argument can be passed. This tells the setup script to use the last tested commits to the OQS project repositories and can be performed using the following commands:

```
git clone -b main https://github.com/crt26/pqc-eval-tools.git
cd pqc-eval-tools
./setup.sh --safe-setup
```

### Ensuring Root Dir Path Marker is Present
It is vital that when performing either setup option that this is done from within the projects root directory. This is because during the automated setup, a hidden temp file will be generated at the projects root called `.pqc_eval_dir_marker.tmp`. This used by  the other automation scripts to determine where the projects root directory is which is vital for their operation. 

Please do not remove this file whilst the project is in a configured state. This file will be removed when uninstalling all libraries using the `cleaner.sh` utility script. If the file is removed outwith that utility script, it can be regenerated manually or by rerunning the main setup script. 

To verify the presence of the marker file, the following command can be performed to list the full contents of the directory including hidden files:
```
ls -la
```

To manually regenerate the file, move into the projects root directory and execute the following command:

```
touch .pqc_eval_dir_marker.tmp
```

## Automated Testing Tools

### Tools Description
There are two sets of automated testing that can be done using these tools:

- PQC performance benchmarking using Liboqs
- PQC integration into TLS 1.3 performance benchmarking using OQS-Provider

The testing tools can be found within the `scripts/test-scripts` directory and are fully automated. The tools allow multiple machines to be tested, with results being assigned a number set at the beginning of the test. The testing scripts are as follows:

### Liboqs Performance Testing

This script automates the CPU and memory performance benchmarking of various PQC algorithms included in the Liboqs library. It generates and records comprehensive metrics which can help in analysing the performance of these algorithms. 

The test script can be executed using the following command:
```
./full-liboqs-test.sh
```

#### Detailed usage instructions can be found using the following link:

[Liboqs Performance Automated Testing Instructions](docs/testing-tools-documentation/liboqs-performance-testing.md)

### OQS-Provider Performance Testing

This script is focused on benchmarking the performance of PQC and Hybrid-PQC algorithms when integrated within the OpenSSL (3.4.1) library via the OQS-Provider. The script firstly can test the computational efficiency of the PQC algorithms when integrated into the OpenSSL library. Alongside, how PQC/Hybrid-PQC algorithms perform when integrated into the TLS protocol by measuring empty TLS handshake performance. Furthermore, metrics for how classic algorithms perform when conducting the TLS handshake which can be used as a baseline to compare the PQC metrics against.  

The testing tool allows for tests to be conducted on a single machine or using two machines connected via a physical network. It should be noted that when using two physical machines the complexity of setup increases. However, regardless of which scenario, the process requires more additional steps then the Liboqs testing.

#### Detailed usage instructions can be found using the following link:

[PQC TLS Performance Automated Testing Instructions](docs/testing-tools-documentation/tls-performance-testing.md)


### Testing Output Files
After selecting the desired testing script, the performance benchmarks will be performed and the unparsed results will be stored in the newly created ``test-data/up-results`` directory. Liboqs unparsed results will be stored in the `test-data/up-results/liboqs/machine-x`* directory. The PQC TLS 1.3 test results will be stored in the `test-data/up-results/oqs-provider/machine-x`* directory.

**The Machine-ID number assigned to the test*


## Parsing Test Results

### Parsing Overview

The results from the automated tests can be transformed into workable CSV files using the `parse_results.py` script located in the `scripts/parsing-scripts` directory. Options are provided to parse the liboqs results, the OQS-Provider results, or both.

The script requires the test parameters used during the benchmarking, including the number of runs and number of machines tested, (if multiple machine results have been copied to the `test-data/up-results` directory). Please make sure all up-results are present in this directory that you wish to be parsed before executing the `parse_results.py` script.


### Parsing Script Usage

The parsing process, unlike the testing scripts, can be executed on both Linux and Windows machines. If you're parsing results from multiple machines, make sure all results are present in the `up-results` directory. Execute the parsing script with the following commands depending on the default Python command alias:

```
python3 parse_results.py
```


### Parsed Results Output
At the end of the process, the results will be stored within the newly created **results** directory which can be found in the results folder in `test-data/results`. Averages for the results will also be calculated during the parsing process and the average files for the respective test type can be found within the same results directory.

### Graph Generation
The results files outputted from the parsing scripts can be used with Microsoft Excel, Python, R-Studio etc. for the creation of graphs, helpful links for data visualisation can be found below:

- [Visualising Data with Python](https://www.geeksforgeeks.org/data-visualization-with-python/)
- [Data Visualisation with Python Pandas](https://realpython.com/pandas-plot-python/)
- [Data Visualisation with R](https://www.dataquest.io/blog/data-visualization-in-r-with-ggplot2-a-beginner-tutorial/)
- [Microsoft Excel Chart Creation](https://support.microsoft.com/en-us/office/create-a-chart-from-start-to-finish-0baf399e-dd61-4e18-8a73-b3fd5d5680c2)


## Utility Scripts
The utility scripts provided may be useful when developing or testing the various scripts contained in the repository or when setting up performance testing environments. More refined and encompassing utility scripts will be added as the project progresses. All utility scripts bar the `cleaner.sh` script can be found in the `scripts/utility-scripts` directory. The `cleaner.sh` script is instead stored at the projects root for ease of access.

The current set of utility scripts includes:

### cleaner.sh <!-- omit from toc --> 
This is a utility script for cleaning the various project files produced from the compiling and benchmarking operations. The script provides functionality for either uninstalling the OQS and other dependency libraries from the system, clearing the old results and generated TLS keys, or both.

### get_algorithms.py <!-- omit from toc --> 
This is a Python utility script which is used to dynamically determine the algorithms which are supported by the version of Liboqs and OQS-Provider libraries installed. These are then outputted accordingly to the `test-data/alg-lists` text files for the different algorithm and test types. The main usage of the script is to be called from the `setup.sh` script where it is passed an argument which dictates which install type is being performed in the setup process. There is also the option to call the `get_algorithms.py` manually to create the algorithm list files if required.

Based on the the install type that has been selected in the main setup script, the following integer arguments can be supplied to the utility script:

- 1 - (Liboqs only)
- 2 - (Liboqs and OQS-Provider)
- 3 - (OQS-Provider only)


Example usage when running manually:
```
cd scripts/utility-scripts
python3 get_algorithms.py 1
```

### configure-openssl-cnf.sh <!-- omit from toc --> 
This script can change the configurations added to the OpenSSL 3.4.1 configuration file by commenting or uncommenting the lines which set what default groups OpenSSL uses. This is needed to allow both the `oqsprovider-generate-keys.sh` and the TLS performance testing scripts to operate correctly. This script is mainly used by the automated scripts, however it can be called manually using the following commands:

**configure-openssl-cnf.sh - Comment out Default Group Configurations:**
```
./configure-openssl-cnf.sh 0
```

**configure-openssl-cnf.sh - Uncomment out Default Group Configurations:**
```
./configure-openssl-cnf.sh 1
```

> Notice: As the `configure-openssl-cnf.sh` script is intended mainly to be used by the automated testing scripts, please take caution when calling the script manually. This is due to how the script anticipates the state of the configuration file. If calling manually ensure to verify the openssl.cnf file for any double comments or other misconfigurations.

## Repository Directory Structure

### Overview
The repository will contain default directories and files that are present when cloned and during operation will create various directories required for its functionality. In the following diagram and descriptions, directories and files that are created by the scripts are marked with a "*" next to their name wherever they appear in this section.

### Layout and Descriptions
The pqc-eval-tools repository directories are organised as follows:

```
pqc-eval-tools/
│
├── docs
│   └── result-info
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
    ├── alg-lists*
    ├── results*
    └── up-results*
```

#### Directory Description

- **docs**: Contains various documentation files related to the repository and its functionality.

- **lib***: This directory will contain the various libraries which are used by the project to conduct the performance testing after the setup operations have been performed. This will includes libraries provided by the OQS Project, OpenSSL and Pqax.

- **modded-lib-files**: Contains OQS project files that have been modified for the purpose of this repositories functionality.

- **test-data**: Contains various sub-directories for the data required to operate the automated testing scripts and is where the results directories will be generated and stored.

  - **alg-lists**: Contains various text files which list the quantum algorithms used by the scripts within the project. These text files are dynamically created at setup and will contain the algorithms supported by the versions of the OQS libraries installed at runtime.

  - **results***: Contains the parsed results created by the Python parsing scripts.

  - **up-results*** Contains the outputted un-parsed results from the automated benchmarking scripts. The performance metrics stored in these files will not be ready for interpretation yet, and will need parsed using the Python parsing scripts provided by the project before they can be used.

- **scripts**: Contains the various sub-directories which houses the testing, parsing, and utility scripts. 
  
  - parsing-scripts: Contains scripts used for parsing the un-parsed results data outputted to the `test-data/up-results` directory.
  
  - test-scripts: Contains scripts that are used for testing various components of the project.

  - utility-scripts: Contains the utility scripts used by the user and the automated testing scripts.

## Helpful Documentation Links
- [liboqs Webpage](https://openquantumsafe.org/liboqs/)
- [liboqs GitHub Page](https://github.com/open-quantum-safe/liboqs)
- [OQS-Provider Webpage](https://openquantumsafe.org/applications/tls.html#oqs-openssl-provider)
- [OQS-Provider GitHub Page](https://github.com/open-quantum-safe/oqs-provider)
- [Latest liboqs Release Notes](https://github.com/open-quantum-safe/liboqs/blob/main/RELEASE.md)
- [Latest OQS-Provider Release Notes](https://github.com/open-quantum-safe/oqs-provider/blob/main/RELEASE.md)
- [OpenSSL(3.4.1) Documentation](https://docs.openssl.org/3.4/)
- [TLS 1.3 RFC 8446](https://www.rfc-editor.org/rfc/rfc8446)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE)

## Acknowledgements
This project depends on:

1. [Liboqs](https://github.com/open-quantum-safe/liboqs) - This project includes modified versions of files from the `liboqs` project. These modified files are subject to the `liboqs` MIT license, which can be found at the top of each modified file.

2. [OQS-Provider](https://github.com/open-quantum-safe/openssl) - This project relies on the OpenSSL provider created by the `OQS-Provider` project. The project is subject to a MIT licence, details of which can be found in the projects repositories root directory. 

3. [OpenSSL](https://github.com/openssl/openssl) - This project utilises the OpenSSL library through its own scripts and the libraries provided by the OQS Project. The OpenSSL project is  under the Apache 2.0 license, details of which can be found in the projects repositories root directory.

4. [pqax](https://github.com/mupq/pqax/tree/main) - This project uses the pqax library to enable arm PMU on Raspberry Pi devices. The pqax library is licensed under the Creative Commons Zero v1.0 Universal license, which dedicates the work to the public domain.
