# Automated PQC Performance Benchmarking Tool Usage Guide <!-- omit from toc -->

## Overview <!-- omit from toc -->
This guide provides detailed instructions for using the automated Post-Quantum Cryptographic (PQC) computational performance testing tool. It allows users to gather benchmarking data for PQC algorithms using the Open Quantum Safe (OQS) Liboqs library. Results are collected automatically and can be customised with user-defined test parameters.

The tool outputs raw performance metrics in CSV and text formats, which are later parsed using Python scripts for easier interpretation and analysis.

### Contents <!-- omit from toc -->
- [Supported Hardware and Software](#supported-hardware-and-software)
- [Performing PQC Computational Performance Testing](#performing-pqc-computational-performance-testing)
  - [Running the Liboqs Testing Tool](#running-the-liboqs-testing-tool)
  - [Configuring Testing Parameters](#configuring-testing-parameters)
- [Outputted Results](#outputted-results)
- [Useful External Documentation](#useful-external-documentation)

## Supported Hardware and Software
The automated testing tool is currently only supported on the following devices:

- x86 Linux Machines using a Debian-based operating system
- ARM Linux devices using a 64-bit Debian based Operating System

**Notice:** The HQC KEM algorithms are disabled by default in recent Liboqs versions due to a disclosed IND-CCA2 vulnerability. For benchmarking purposes, the setup process includes an optional flag to enable HQC, accompanied by a user confirmation prompt and warning. For instructions on enabling HQC, see the [Advanced Setup Configuration Guide](../advanced-setup-configuration.md), and refer to the [Disclaimer Document](../../DISCLAIMER.md) for more information on this issue.

## Performing PQC Computational Performance Testing

### Running the Liboqs Testing Tool
The automated test script is located in the `scripts/testing-scripts` directory and can be launched using the following commands:

```
./full-liboqs-test.sh
```

When executed, the testing tool will provide various testing parameter options before the benchmarking process begins.

### Configuring Testing Parameters
Before testing begins, the script will prompt you to configure a few testing parameters which includes:

- Whether the results should be compared with other machines and Assigning Machine-ID
- The number of times each test should be run to allow for more accurate average calculation.

#### Machine Comparison Option <!-- omit from toc -->
The first testing option is:

```
Do you intend to compare the results against other machines [y/n]?
```

Selecting `y` (yes) enables multi-machine result comparison. The script will prompt you to assign a machine ID to the results, which the Python parsing scripts use to organise and differentiate data from different systems. This is useful when comparing performance across devices or architectures. Responding  `n` (no) to this option will assign a default value of `1` to the outputted machine results upon test completion.

#### Assigning Number of Test Runs <!-- omit from toc -->
The second testing parameter is the number of test runs that should be performed. The script will present the following option:

```
Enter the number of test runs required:
```

You can then enter a valid integer value to specify the total number of test runs. However, it is important to note that a higher number of runs will significantly increase testing time, especially if the tool is being used on a more constrained device. This feature allows for sufficient gathering of data to perform average calculations, which is vital if conducting research into the performance of PQC algorithms.

## Outputted Results
After testing has completed, performance results are stored in the newly created `test-data/up-results/liboqs/machine-x` directory. This directory stores all of the unparsed results from the automated testing tools.

These results are not yet ready for interpretation or graphing. To convert them into structured CSV files suitable for analysis, refer to the **Parsing Results** section of the main [README](../../README.md) file.

For a detailed description of the Liboqs performance metrics that this project can gather, what they mean, and how this project scripts structure the un-parsed and parsed data, please refer to the [Performance Metrics Guide](../performance-metrics-guide.md).

## Useful External Documentation
- [Liboqs Webpage](https://openquantumsafe.org/liboqs/)
- [Liboqs GitHub Page](https://github.com/open-quantum-safe/liboqs)
- [Latest liboqs Release Notes](https://github.com/open-quantum-safe/liboqs/blob/main/RELEASE.md)
- [Valgrind Massif Tool](http://valgrind.org/docs/manual/ms-manual.html)
- [OQS Benchmarking Webpage](https://openquantumsafe.org/benchmarking/)
- [OQS Profiling Project](https://openquantumsafe.org/benchmarking/)