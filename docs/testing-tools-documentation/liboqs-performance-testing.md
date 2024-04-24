# Automated PQC Performance Benchmarking Tool Usage Guide <!-- omit from toc --> 

## Contents <!-- omit from toc --> 
- [Overview](#overview)
- [Getting Started](#getting-started)
- [Configuring Test Parameters](#configuring-test-parameters)
- [Outputted Results](#outputted-results)
- [Included Testing Functionality](#included-testing-functionality)
- [Useful Documentation](#useful-documentation)


## Overview
This guide will provide detailed instructions on the usage of the automated PQC performance tool. This tool allows for the automatic gathering of PQC performance data and can it can be customised to use varying testing parameters. The tool uses the Open Quantum Safe Liboqs library benchmarking tools to gather performance metrics and output them into CSV files which can then be parsed by Python scripts for proper interpretation.

### Supported Hardware <!-- omit from toc --> 
The automated testing tool is currently only supported on the following devices:

- x86 Debian Based Linux Machines
- ARMv8 Raspberry Pis using a 64-bit Architecture

> Notice: As this is a early release version of the testing suites, the supported hardware is currently limited. However, future versions will address this issue and allow for support on a wider range of architectures and operating systems.

## Getting Started
The automated test script for can be found within the `scripts/testing-scripts` directory. The tool can be activated using the following commands from the **codes root directory**:

```
cd scripts/testing-scripts
./full-liboqs-test.sh
```

Upon starting the testing tool, various option inputs will be presented which allow for the configuration of testing parameters.

## Configuring Test Parameters
To set the parameters for the test, various values will be requested by the script before starting testing. They are as follows:

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

When requested, assign a numeric value that will be used by the system to identify results from this machine. The script will also handle any clashes with the Machine-ID set and any results that are currently stored from previous results by offering the user the option to change the Machine-ID for testing or to replace currently stored results for that Machine-ID.

### Assigning Number of Test Runs <!-- omit from toc --> 
The final testing parameter is the number of test runs that should be performed. The following option will be presented by the script:

```
Enter the number of test runs required:
```

Input a valid integer for this option. However, it is important to note that higher number of runs will significantly increase testing time, especially if the tool is being used on a more constrained device. This feature allows for sufficient gathering of data to perform average calculation, which is vital if conducting research into the performance of PQC algorithms.

## Outputted Results
The outputted results from the automated testing tool will be stored in the newly created `test-data/up-results/liboqs/machine-x` directory which can be found within the code's root directory. This directory is used to store all of the unparsed results from the automated testing tools. 

The data stored is not yet ready for interpretation or graph generation. To parse the data into a format that can be used for further analysis please refer to the [parsing results](../../README.md) section  within the readme file.


## Included Testing Functionality
The bash scripts used by the automated tool gathers PQC performance metrics using a combination of the liboqs library alongside other tools such as the Valgrind Massif Memory Profiler. The main controlling script `full-liboqs-test.sh` calls upon two main functions for performing benchmarking:

- **speed_tests()**- to gather PQC speed metrics
- **mem_tests()**- to gather PQC memory metrics

### Speed Test Functionality <!-- omit from toc --> 
This function automates the liboqs speed benchmarking tests, executing them according to the parameters specified within the liboqs test control script. The script uses the liboqs `speed-kem.c` and `speed-sig.c` benchmarking programmes to gather performance metrics. The script performs the speed tests and writes the output to the `test-data/up-results/liboqs/machine-x/raw-speed-results` directory.

### Memory Testing Functionality <!-- omit from toc --> 
This function automates the gathering of PQC memory metrics using a combination of the liboqs `test-kem-mem.c` and `test-sig-mem.c` memory testing programmes and the Valgrind Massif memory profiler tool to measure the memory statistics of a provided PQC Algorithm/operation combination execution. The memory tests are performed for a specified number of runs, and the test results are written to the mem-results directory for each run. Upon completion, the memory test results are moved to the `test-data/up-results/liboqs/machine-x/mem-results` directory. The data, like the speed results, will need to be further parsed as the results are the outputs of the Massif memory tool output stored within a text file. The data can be parsed into CSV format, which includes metrics such as maxHeap and maxStack using the python parsing scripts detailed in the [parsing results](../../README.md) section of the main README file.


## Useful Documentation
- [liboqs Webpage](https://openquantumsafe.org/liboqs/)
- [liboqs GitHub Page](https://github.com/open-quantum-safe/liboqs)
- [Latest liboqs Release Notes](https://github.com/open-quantum-safe/liboqs/blob/main/RELEASE.md)
- [Valgrind Massif Tool](http://valgrind.org/docs/manual/ms-manual.html)
- [OQS Benchmarking Webpage](https://openquantumsafe.org/benchmarking/)
- [OQS Profiling Project](https://openquantumsafe.org/benchmarking/)