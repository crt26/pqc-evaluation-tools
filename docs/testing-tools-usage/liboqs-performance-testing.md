# Automated PQC Performance Benchmarking Tool Usage Guide <!-- omit from toc -->

## Overview <!-- omit from toc -->
This guide provides detailed instructions for using the automated Post-Quantum Cryptographic (PQC) computational performance testing tool. It allows users to gather benchmarking data for PQC algorithms using the Open Quantum Safe (OQS) `Liboqs` library. Results are collected automatically and can be customized with user-defined test parameters.

The tool outputs raw performance metrics in CSV format, which are later parsed using Python scripts for easier interpretation and analysis.

### Contents <!-- omit from toc -->
- [Supported Hardware](#supported-hardware)
- [Performing PQC Computational Performance Testing](#performing-pqc-computational-performance-testing)
  - [Running the Liboqs Testing Tool](#running-the-liboqs-testing-tool)
  - [Configuring Testing Parameters](#configuring-testing-parameters)
- [Outputted Results](#outputted-results)
- [Included Testing Functionality](#included-testing-functionality)
- [Useful External Documentation](#useful-external-documentation)

## Supported Hardware
The automated testing tool is currently only supported on the following devices:

- x86 Linux Machines using a Debian based operating system
- ARM Linux devices using a 64-bit Debian based Operating System

## Performing PQC Computational Performance Testing

### Running the Liboqs Testing Tool
The automated test script is located in the `scripts/testing-scripts` directory and can be launched using the following commands:

```
./full-liboqs-test.sh
```

When executed, the testing tool will provide various testing parameter options before the benchmarking process begins.

### Configuring Testing Parameters
Before testing begins, the script will prompt you to configure a few parameters. These include:

- Whether the results should be compared with other machines and Assigning Machine-ID
- The number of times each test should be ran, to allow for more accurate average calculation.

#### Machine Comparison Option <!-- omit from toc -->
The first testing option is:

```
Do you intend to compare the results against other machines [y/n]?
```

Selecting `y` (yes) enables multi-machine result comparison. A machine number will be assigned to the output, which is used by the Python parsing scripts to organize and differentiate data from different systems. This is useful when comparing performance across devices or architectures. Responding  `n` (no) to this option will then skip the second testing option and assign a default value of `1` to the outputted machine results upon test completion.

If the response to the machine comparison query is "yes", the script will then prompt to assign a number to the results from the machine. A numeric value that will be used by the system to identify results from this machine can then be assigned.

#### Assigning Number of Test Runs <!-- omit from toc -->
The second testing parameter is the number of test runs that should be performed. The following option will be presented by the script:

```
Enter the number of test runs required:
```

Input a valid integer for this option. However, it is important to note that higher number of runs will significantly increase testing time, especially if the tool is being used on a more constrained device. This feature allows for sufficient gathering of data to perform average calculation, which is vital if conducting research into the performance of PQC algorithms.

## Outputted Results
After testing completes, performance results are then stored in the newly created `test-data/up-results/liboqs/machine-x` directory. This directory is used to store all of the unparsed results from the automated testing tools.

These results are not yet ready for interpretation or graphing. To convert them into structured CSV files suitable for analysis, refer to the **Parsing Results** section of the main README file.

For a detailed description of the Liboqs performance metrics that this project can gather, what the mean, and how the un-parsed and parsed data is structured by this projects scripts, please refer to the [Performance Metrics Guide](../performance-metrics-guide.md).

## Included Testing Functionality
The automated benchmarking tool collects PQC computational performance data using a combination of the Liboqs library and the Valgrind Massif memory profiler. The main controlling script `full-liboqs-test.sh` calls upon two main functions for performing benchmarking:

- **speed_tests()**- to gather PQC speed metrics
- **mem_tests()**- to gather PQC memory metrics

### Speed Test Functionality <!-- omit from toc -->
The speed_tests() function automates performance benchmarking using the Liboqs speed tools: `speed-kem.c` and `speed-sig.c`. These programs benchmark the execution speed of key encapsulation and digital signature algorithms. Results are then outputted to the `test-data/up-results/liboqs/machine-x/raw-speed-results` directory.

### Memory Testing Functionality <!-- omit from toc -->
The mem_tests() function gathers memory usage data using Liboqs’s `test-kem-mem.c` and `test-sig-mem.c` tools, in combination with the Valgrind Massif profiler. This setup captures detailed memory statistics for KEM and signature operations. For each test run, raw memory profiling data is stored in a temporary directory, then moved to the `test-data/up-results/liboqs/machine-x/mem-results` directory.

These output files are Valgrind Massif logs in plain text and must be parsed into CSV format before analysis. The parsing process extracts key metrics such as maxHeap and maxStack, and is described in the **Parsing Results** section of the main README file.

## Useful External Documentation
- [Liboqs Webpage](https://openquantumsafe.org/liboqs/)
- [Liboqs GitHub Page](https://github.com/open-quantum-safe/liboqs)
- [Latest liboqs Release Notes](https://github.com/open-quantum-safe/liboqs/blob/main/RELEASE.md)
- [Valgrind Massif Tool](http://valgrind.org/docs/manual/ms-manual.html)
- [OQS Benchmarking Webpage](https://openquantumsafe.org/benchmarking/)
- [OQS Profiling Project](https://openquantumsafe.org/benchmarking/)