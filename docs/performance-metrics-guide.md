# PQC Performance Metrics & Results Storage Breakdown <!-- omit from toc -->

## Overview <!-- omit from toc -->
This document provides a comprehensive guide to the performance metrics collected by the project's automated benchmarking tools for Post-Quantum Cryptography (PQC) algorithms using the Open Quantum Safe Project.

This documentation explains not only the types of metrics collected, but also how the raw data is structured, parsed, and analysed across different test environments by the automated testing and parsing scripts this projects provides.

Below is a list of the topics the document covers:

- A background overview of the cryptographic operations used in PQC digital signature schemes and Key Encapsulation Mechanisms (KEMs)

- A description of the computational performance metrics gathered by the automated Liboqs performance testing

- A detailed explanation of how the data gathered by the Liboqs testing is stored and organised within this project

- A description of the PQC TLS performance metrics gathered by the automated OQS-Provider TLS testing

- A detailed explanation of how the data gathered by the OQS-Provider TLS testing is stored and organised within this project

### Contents <!-- omit from toc -->
- [Description of Post-Quantum Cryptographic Operations](#description-of-post-quantum-cryptographic-operations)
  - [Digital Signature Operations](#digital-signature-operations)
  - [Key Encapsulation Mechanism (KEM) Operations](#key-encapsulation-mechanism-kem-operations)
- [Liboqs Computational Performance Metrics](#liboqs-computational-performance-metrics)
  - [CPU Benchmarking](#cpu-benchmarking)
  - [Memory Benchmarking](#memory-benchmarking)
- [Liboqs Result Data Storage Structure](#liboqs-result-data-storage-structure)
- [OQS-Provider PQC TLS Performance Metrics](#oqs-provider-pqc-tls-performance-metrics)
  - [TLS Handshake Testing](#tls-handshake-testing)
  - [TLS Speed Testing](#tls-speed-testing)
- [OQS-Provider Result Data Storage Structure](#oqs-provider-result-data-storage-structure)
- [Useful External Documentation](#useful-external-documentation)

## Description of Post-Quantum Cryptographic Operations
Post-Quantum Cryptography (PQC) algorithms are broadly into two categories: Digital Signature Schemes and Key Encapsulation Mechanisms (KEMs). Each category consists of three cryptographic operations that define the algorithm’s core functionality.

This section provides a brief overview of these operations to support the of the performance metrics descriptions detailed in this document.

### Digital Signature Operations

| **Operation Name** | **Internal Label** | **Description**                                                         |
|------------------------|--------------------|-------------------------------------------------------------------------|
| Key Generation         | keypair            | Generates a public/private keypair for the digital signature algorithm. |
| Signing                | sign               | Uses the private key to generate a digital signature over a message.    |
| Verification           | verify             | Uses the public key to verify the authenticity of a digital signature.  |

### Key Encapsulation Mechanism (KEM) Operations

| **Operation Name** | **Internal Label** | **Description**                                                        |
|------------------------|--------------------|------------------------------------------------------------------------|
| Key Generation         | keygen             | Generates a public/private keypair for the KEM algorithm.              |
| Encapsulation          | encaps             | Uses the public key to generate a shared secret and ciphertext.        |
| Decapsulation          | decaps             | Uses the private key to recover the shared secret from the ciphertext. |

## Liboqs Computational Performance Metrics
The tests are performed for both PQC digital signatures and KEM algorithms to gather detailed CPU and memory performance metrics. Using the Liboqs library, the automated testing tool executes each cryptographic operation repeatedly, collecting data that helps evaluate the algorithm’s computational efficiency and resource usage on a given system.

These results are useful for comparing algorithm performance across different hardware environments, understanding real-world operational cost, and informing decisions in PQC deployment or research. The output is separated into CPU and memory benchmarking sections for clearer analysis.

### CPU Benchmarking
The CPU benchmarking results measure the execution time and efficiency of various cryptographic operations for each PQC algorithm, including keypair generation, signing, and verification.

Using the Liboqs benchmarking tools, each operation is run repeatedly within a fixed time window (3 seconds by default). The tool performs as many iterations as possible in that time frame and records detailed performance metrics.

The table below describes the metrics included in the CPU benchmarking results:

| **Metric**          | **Description**                                                           |
|---------------------|---------------------------------------------------------------------------|
| Iterations          | Number of times the operation was executed during the test window.        |
| Total Time (s)      | Total duration of the test run (typically fixed at 3 seconds).            |
| Time (us): mean     | Average time per operation in microseconds.                               |
| pop. stdev          | Population standard deviation of the operation time, indicating variance. |
| CPU cycles: mean    | Average number of CPU cycles required per operation.                      |
| pop. stdev (cycles) | Standard deviation of CPU cycles per operation, indicating consistency.   |

### Memory Benchmarking
The memory benchmarking tool evaluates how much memory is consumed by individual PQC cryptographic operations when executed on the system. This is accomplished by running the `test-kem-mem` and `test-sig-men` Liboqs tools for each PQC algorithm and its respective operations with the Valgrind Massif profiler.

Each operation is performed once with the Valgrind Massif profiler to gather peak memory usage, and can be tested across multiple runs to ensure consistency. After each run of testing, memory profiling output is parsed into structured CSV format, with each row corresponding to a single algorithm-operation combination.

The following table describes the memory-related metrics captured during parsing:

| **Metric** | **Description**                                                                 |
|------------|---------------------------------------------------------------------------------|
| inits      | Number of memory snapshots (or samples) collected by Valgrind during profiling. |
| maxBytes   | Peak total memory usage across all memory segments (heap + stack + others).     |
| maxHeap    | Maximum memory allocated on the heap during execution of the operation.         |
| extHeap    | Heap memory allocated externally (e.g., through system libraries).              |
| maxStack   | Maximum stack memory usage recorded during the test.                            |

## Liboqs Result Data Storage Structure
When using the Liboqs benchmarking script (`full-liboqs-test.sh`), all performance data is initially stored as un-parsed output. This raw data is then processed using the Python parsing script to generate structured CSV files for analysis, including averages across test runs.

The table below outlines where this data is stored and how it's organised in the project's directory structure:

| **Data Type**        | **State** | **Description**                                                                                                                                       | **Location**                                                      |
|----------------------|-----------|-------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------|
| CPU Speed            | Un-parsed | Raw `.csv` outputs directly from `speed_kem` and `speed_sig` binaries                                                                                 | `test-data/up-results/liboqs/machine-X/raw-speed-results/`        |
| CPU Speed            | Parsed    | Cleaned CSV files with per-algorithm speed metrics and averages                                                                                       | `test-data/results/liboqs/machine-X/speed-results/`               |
| Memory Usage         | Un-parsed | Raw `.txt` outputs from Valgrind Massif profiling of digital signature and KEM operations using the Liboqs `test-kem-mem` and `test-sig-mem` binaries | `test-data/up-results/liboqs/machine-X/mem-results/`              |
| Memory Usage         | Parsed    | CSV summaries of peak memory usage for each algorithm-operation                                                                                       | `test-data/results/liboqs/machine-X/mem-results/`                 |
| Performance Averages | Parsed    | Average results for the performance metrics across test runs                                                                                          | Located alongside parsed CSV files in `results/liboqs/machine-X/` |

## OQS-Provider PQC TLS Performance Metrics
The OQS-Provider performance testing captures benchmarking data for PQC and Hybrid-PQC algorithms integrated into the OpenSSL 3.4.1 library. These results reflect how PQC schemes perform when integrated into TLS 1.3, as well as their cryptographic operation performance when executed directly through OpenSSL. This testing provides a great insight into how the PQC schemes perform when integrated into real-world security protocols. Additionally, TLS handshake metrics are also gathered when using classical digital algorithms and ciphersuites to provide a baseline to compare the PQC/PQC-Hybrid performance data too.

As part of the automated TLS testing, two categories of evaluations are conducted:

- **TLS Handshake Testing** - This simulates full TLS 1.3 handshakes using OpenSSL’s s_server and s_time tools, evaluating both standard and session-resumed connections.

- **TLS Speed Testing** - This uses the OpenSSL s_speed tool to benchmark the algorithm’s low-level operations such as key generation, encapsulation, signing, and verification.

### TLS Handshake Testing
The TLS handshake performance tests measure how efficiently different PQC, Hybrid-PQC, and classical algorithm combinations perform during the TLS 1.3 handshake process. These tests are executed using OpenSSL's built-in benchmarking tools (s_server and s_time) with the OQS-Provider integration.

Each test performs the TLS handshake for a given digital signature and KEM algorithm combination (digital signature) as many times as possible for a given time window, for both with and without session ID reuse to evaluate the impact of session resumption on performance.

The table below provides a description of the performance metrics gathered during this testing:

| **Metric**                                  | **Description**                                                                                                   |
|---------------------------------------------|-------------------------------------------------------------------------------------------------------------------|
| Connections in User Time                    | Number of successful TLS handshakes completed during CPU/user time. Reflects algorithm efficiency per CPU second. |
| Connections per User Second                 | Handshake rate per CPU second. Indicates performance under ideal CPU conditions.                                  |
| Real Time                                   | Total wall clock time elapsed, including system I/O and process delays.                                           |
| Connections in Real Time                    | Number of handshakes completed in actual wall time. Useful for real-world performance assessment.                 |
| Connections per User Second (Session Reuse) | Handshake rate per CPU second with session ID reuse. Measures efficiency with session resumption.                 |
| Connections in Real Time (Session Reuse)    | Handshakes per real-world time with session reuse. Reflects practical performance with resumed sessions.          |

### TLS Speed Testing
TLS speed testing benchmarks the raw cryptographic performance of PQC and Hybrid-PQC algorithms when integrated into the OpenSSL library via the OQS-Provider. This is done using the OpenSSL `s_speed` tool, which measures both the execution time and throughput of cryptographic operations for each algorithm.

The primary objective of this test is to gather the base system performance of the schemes when integrated into the OpenSSL library, rather than the TLS handshake tests which assess both system performance and networking performance. The results provide insight into the algorithm’s standalone efficiency when running within OpenSSL which can provide additional overhead compared to the performance tests provided by Liboqs.

#### Digital Signature Algorithm Metrics
The following table describes the metrics collected for digital signature algorithms during TLS speed testing:

| **Metric**   | **Description**                                                                  |
|--------------|----------------------------------------------------------------------------------|
| keygen (s)   | Average time in seconds to generate a signature keypair.                         |
| sign (s)     | Average time in seconds to perform a signing operation.                          |
| verify (s)   | Average time in seconds to verify a digital signature.                           |
| keygens/s    | Number of key generation operations completed per second.                        |
| signs/s      | Number of signing operations completed per second.                               |
| verifies/s   | Number of verification operations completed per second.                          |

#### KEM Algorithm Metrics
The following table describes the metrics collected for Key Encapsulation Mechanism (KEM) algorithms during TLS speed testing:

| **Metric**   | **Description**                                                                 |
|--------------|---------------------------------------------------------------------------------|
| keygen (s)   | Average time in seconds to generate a keypair.                                  |
| encaps (s)   | Average time in seconds to perform an encapsulation operation.                  |
| decaps (s)   | Average time in seconds to perform a decapsulation operation.                   |
| keygens/s    | Number of key generation operations completed per second.                       |
| encaps/s     | Number of encapsulation operations completed per second.                        |
| decaps/s     | Number of decapsulation operations completed per second.                        |

## OQS-Provider Result Data Storage Structure
When running the OQS-Provider TLS benchmarking script (`full-oqs-provider-test.sh`), all performance data is initially stored as unparsed output on the client machine. This raw data is then processed using the Python parsing script to generate structured CSV files for analysis, including averaged metrics across multiple test runs.

| **Data Type**   | **State**     | **Description**                                                                                             | **Location**                                                                                       |
|-----------------|---------------|-------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------|
| TLS Handshake   | Un-parsed     | Raw `.txt` outputs from OpenSSL `s_time` tests for PQC, Hybrid-PQC, and Classic algorithm combinations.     | `test-data/up-results/oqs-provider/machine-X/handshake-results/{pqc/hybrid/classic}`               |
| TLS Handshake   | Parsed        | Per-run CSVs with extracted handshake metrics (PQC, Hybrid, Classic), separated by each digital signature   | `test-data/results/oqs-provider/machine-X/handshake-results/{pqc/hybrid/classic}/{signature-name}` |
| TLS Handshake   | Parsed (Base) | Full combined metrics for all digital signature and KEM combinations in a single CSV for each run           | `test-data/results/oqs-provider/machine-X/handshake-results/{pqc/hybrid}/base-results`             |
| TLS Speed       | Un-parsed     | Raw `.txt` outputs from `openssl speed` tests for PQC and Hybrid-PQC algorithms (digital signature and KEM) | `test-data/up-results/oqs-provider/machine-X/speed-results/{pqc/hybrid}`                           |
| TLS Speed       | Parsed        | Cleaned CSVs with cryptographic operation timings and throughput per algorithm                              | `test-data/results/oqs-provider/machine-X/speed-results/`                                          |
| Parsed Averages | Parsed        | Averaged handshake/speed metrics across test runs                                                           | Same as parsed result directories (`results/oqs-provider/machine-X/`)                              |

## Useful External Documentation
- [Liboqs Webpage](https://openquantumsafe.org/liboqs/)
- [Liboqs GitHub Page](https://github.com/open-quantum-safe/liboqs)
- [Valgrind Massif Tool](http://valgrind.org/docs/manual/ms-manual.html)
- [OQS-Provider Webpage](https://openquantumsafe.org/applications/tls.html#oqs-openssl-provider)
- [OQS-Provider GitHub Page](https://github.com/open-quantum-safe/oqs-provider)
- [OQS Profiling Project](https://openquantumsafe.org/benchmarking/)
- [OpenSSL(3.4.1) Documentation](https://docs.openssl.org/3.4/)
- [OQS Benchmarking Webpage](https://openquantumsafe.org/benchmarking/)
- [OQS Profiling Project](https://openquantumsafe.org/benchmarking/)