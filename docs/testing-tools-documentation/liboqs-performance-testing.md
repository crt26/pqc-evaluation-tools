# Automated PQC Performance Benchmarking Tool Usage Guide <!-- omit from toc --> 

## Contents <!-- omit from toc --> 
- [Overview](#overview)
- [Getting Started](#getting-started)
- [Configuring Test Parameters](#configuring-test-parameters)
- [Outputted Results](#outputted-results)
- [Included Testing Scripts](#included-testing-scripts)
- [Useful Documentation](#useful-documentation)


## Overview
This guide will provide detailed instructions on the usage of the automated PQC performance tool. This tool allows for the automatic gathering of PQC performance data and can it can be customised to use varying testing parameters. The tool uses the Open Quantum Safe Liboqs library benchmarking tools to gather performance metrics and output them into CSV files which can then be parsed by Python scripts for proper interpretation. The script also handles the required dependencies, and will automatically install any missing packages that may not of been installed when executing the setup script.

### Supported Hardware <!-- omit from toc --> 
The automated testing tool is currently only supported on the following devices:

- x86 Debian Based Linux Machines
- ARMv8 Raspberry Pis using a 64-bit Architecture

> Notice: As this is a early release version of the testing suites, the supported hardware is currently limited. However, future versions will address this issue and allow for support on a wider range of architectures and operating systems.

## Getting Started
The automated test script for can be found within the `testing-scripts` directory. The tool can be activated using the following commands from the **codes root directory**:

```
cd testing-scripts
./full-liboqs-test.sh
```

Upon starting the testing tool, various option inputs will be presented which allow for the configuration of testing parameters.

## Configuring Test Parameters
To set the parameters for the test, various values will be requested by the script before beginning starting. They are as follows:

- Will the results be compared with results from other machines?
- Machine number to be assigned to results, allowing for result comparison.
- The number of times each test should be ran, to allow for more accurate average calculation.

### Machine Comparison Option <!-- omit from toc --> 
The first testing option is:

```
Do you intend to compare the results against other machines [y/n]?
```

Responding "yes" will allow for a machine number to be assigned to the results. This can then allow the Python parsing scripts to utilise the machine number for parsing results from multiple machines simultaneously. This function can be beneficial when comparing results between various hardware types.

Responding "no" to this option will then skip the second testing option and assign a default value of `1` to the outputted machine results upon test completion.

### Assigning Machine Number <!-- omit from toc --> 
If the response to the machine comparison query is "yes", the script will then prompt to assign a number to the machine with the question:

```
What machine number would you like to assign to these results?
```

When requested, assign a numeric value that will be used by the system to identify results from this machine.

### Assigning Number of Test Runs <!-- omit from toc --> 
The final testing parameter is the number of test runs that should be performed. The following option will be presented by the script:

```
Enter the number of test runs required:
```

Input a valid integer for this option. However, it is important to note that higher number of runs will significantly increase testing time, especially if the tool is being used on a more constrained device. This feature allows for sufficient gathering of data to perform average calculation, which is vital if conducting research into the performance of PQC algorithms.

## Outputted Results
The outputted results from the automated testing tool will be stored in the newly created `up-results/liboqs` directory which can be found within the code's root directory. This directory is used to store all of the unparsed results from the automated testing tools. 

The data stored is not yet ready for interpretation or graph generation. To parse the data into a format that can be used for further analysis please refer to the [parsing results](../../README.md) section  within the readme file.

>IMPORTANT NOTE - Activating the automated tools will delete all results currently stored in the up-results directory. To retain previous results, these should be moved to another location prior to re-running the automated test tool.

## Included Testing Scripts
The bash scripts used by the automated tool gathers PQC performance metrics using a combinations the liboqs library alongside other tools such as the Valgrind Massif Memory Profiler. The main controlling script `full-liboqs-test.sh` calls upon two main scripts for performing benchmarking:

- **liboqs-speed-test.sh**- to gather PQC speed metrics
- **liboqs-mem-test.sh**- to gather PQC memory metrics

### liboqs-speed-test.sh <!-- omit from toc --> 
This script automates the liboqs speed benchmarking tests, executing them according to the parameters specified within the liboqs test control script. The script uses the liboqs `speed-kem.c` and `speed-sig.c` benchmarking programmes to gather performance metrics.

#### Description of Script Functionality:
The script first identifies the build directory and clears any old results before commencing the benchmarking process. The number of test runs is determined based on the value you input when prompted by the script. The script performs the speed tests and writes the output to the `speed-results` directory for each test run. Upon completion, the results are moved to the `up-results` directory.

### liboqs-mem-test.sh <!-- omit from toc --> 
This script automates the gathering of PQC memory metrics using a combination of the liboqs `test-kem-mem.c` and `test-sig-mem.c` memory testing programmes and the Valgrind Massif memory profiler tool to measure the memory statistics of a provided PQC Algorithm/opeation combination execution.

#### Description of Script Functionality:
The memory tests are performed for a specified number of runs, and the test results are written to the mem-results directory for each run. Upon completion, the memory test results are moved to the up-results directory. The data, like the speed results, will need to be further parsed as the results are the outputs of the Massif memory tool output stored within a text file. The data can be parsed into CSV format, which includes metrics such as maxHeap and maxStack using the python parsing scripts detailed in the [parsing results](../../README.md) section of the main README file.


## Useful Documentation
- [Liboqs Webpage](https://openquantumsafe.org/liboqs/)
- [Liboqs GitHub Page](https://github.com/open-quantum-safe/liboqs)
- [Latest Liboqs Release Notes](https://github.com/open-quantum-safe/liboqs/releases/tag/0.8.0)
- [Valgrind Massif Tool](http://valgrind.org/docs/manual/ms-manual.html)
- [OQS Benchmarking Webpage](https://openquantumsafe.org/benchmarking/)
- [OQS Profiling Project](https://openquantumsafe.org/benchmarking/)