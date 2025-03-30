# Automated PQC TLS Performance Benchmarking Tool Usage Guide <!-- omit from toc -->

## Overview <!-- omit from toc -->
This tool provides automated benchmarking for PQC-enabled TLS 1.3 handshakes and cryptographic operation performance using the `OQS-Provider` and `OpenSSL 3.4.1`. It tests TLS handshakes using various combinations of PQC and Hybrid-PQC ciphersuites, alongside measuring  cryptographic speed performance of these algorithms when integrated into OpenSSL. In addition to PQC-focused benchmarks, the tool also tests classic algorithms to establish baseline comparisons. Testing can be performed on a single machine (localhost) or across two networked machines, whether over physical or virtual.

All of the relevant scripts for the PQC TLS Performance testing can be found in the `scripts/test-scripts` directory from the project's root.

### Contents <!-- omit from toc -->
- [Supported Hardware](#supported-hardware)
- [Preparing the Testing Environment](#preparing-the-testing-environment)
  - [Control Ports and Firewall Setup for Testing](#control-ports-and-firewall-setup-for-testing)
  - [Generating Required Certificates and Private Keys](#generating-required-certificates-and-private-keys)
- [Performing PQC TLS Performance Testing](#performing-pqc-tls-performance-testing)
  - [Testing Tool Execution](#testing-tool-execution)
  - [Testing Options](#testing-options)
  - [Single Machine Testing](#single-machine-testing)
  - [Separate Server and Client Machine Testing](#separate-server-and-client-machine-testing)
- [Outputted Results](#outputted-results)
- [Advanced Testing Customisation](#advanced-testing-customisation)
  - [Customising Testing Suite TCP Ports](#customising-testing-suite-tcp-ports)
  - [Adjusting Control Signalling](#adjusting-control-signalling)
- [Useful External Documentation](#useful-external-documentation)

## Supported Hardware
The automated testing tool is currently only supported on the following devices:

- x86 Linux Machines using a Debian based operating system
- ARM Linux devices using a 64-bit Debian based Operating System

## Preparing the Testing Environment
Before running any tests, it is crucial to ensure that the necessary setup based on your planned testing environment (single machine/two-machine configuration). This includes allowing required ports through your firewall and generating test server certificates and private-keys.

### Control Ports and Firewall Setup for Testing
The benchmarking tool uses various TCP ports for coordinating testing between the server and client machine, as well as the actual TLS handshake tests themselves. This is the case for both single-machine testing and two-machine testing, so it is crucial that these ports are open and accessible. The server machine must accept incoming connections on the S_Server port to perform TLS handshake testing successfully. These settings apply to both local and remote test configurations.

Please make sure your firewall allows traffic on the following ports:

| **Port Usage**            | **Default TCP Port** |
|---------------------------|----------------------|
| Server Control TCP Port   | 25000                |
| Client Control TCP Port   | 25001                |
| OpenSSL S_Server TCP Port | 4433                 |

If these default ports are unsuitable for your environment, please see the [Test Customisation Section](#advanced-testing-customisation) for further instructions on configuring custom TCP ports.

### Generating Required Certificates and Private Keys
In order to perform the TLS handshake performance tests, the required server certificate and private-key files must first be generated. The generated keys and certificates will be saved to the `test-data/keys` directory in the project root. This can be done by executing the following command from within the `scripts/testing-scripts` directory:

```
./oqsprovider-generate-keys.sh
```

**If you're testing across two machines, copy the entire keys directory to the second machine before proceeding.**

## Performing PQC TLS Performance Testing
Once the testing environment has been properly configured, it is now possible to begin the automated PQC TLS performance testing.

### Testing Tool Execution
To start the automated testing tool, open a terminal in the `scripts/testing-scripts` directory and run the following command:

```
./full-oqs-provider-test.sh
```

Upon executing the script, the testing tool will prompt you to enter the parameters for the test. Depending on the testing scenario (single-machine/two-machines), different setup techniques and options will be required.

**It is also recommended** to refer to the Testing Options section below before beginning testing to ensure all configurations are correct.

### Testing Options
The testing tool will prompt you to enter the parameters for the test. These parameters include:

- Machine type (server or client)
- Machine Comparison Option
- Machine Results ID (if comparison option selected)
- Number of test runs to be performed
- Duration of each TLS handshake tests (if machine is client) **†**
- Duration of TLS speed tests (if machine is client) **††**
- IP address of the other machine (use 127.0.0.1 for single-machine testing)

**†** Defines the duration (in seconds) for each handshake test window. The client will attempt as many TLS handshakes as possible during this period for each algorithm combination.

**††** Defines the duration (in seconds) for benchmarking individual cryptographic operations (e.g., signing or key encapsulation) using the OpenSSL s_speed tool.

### Single Machine Testing
If running the full test locally (single-machine), perform the following steps after generating the required certificates:

#### Server Setup:
1. Run the `full-oqs-provider-test.sh` script

2. Select server when prompted
  
3. Enter the requested test parameters

4. Use 127.0.0.1 as the IP address for the other machine

5. Once the server setup is complete, leave the terminal open and proceed to the client setup

#### Client Setup:
1. In a separate terminal session, run the `full-oqs-provider-test.sh` script again.

2. Select client when prompted

3. Enter the requested test parameters
  
4. Use 127.0.0.1 as the IP address for the other machine

5. The test will begin and results will be stored automatically

### Separate Server and Client Machine Testing
When using two-machines for testing that are connected over a physical/virtual network, one machine will be configured as the server and the other as the client. Please ensure that both machines have the same server certificates and private keys stored in the `test-data/keys` directory before starting.

#### Server Machine Setup:
1. On the server machine, run the `full-oqs-provider-test.sh` script

2. Select server and enter the test parameters when prompted

3. Use the IP address of the client machine when prompted

4. Now begin the setup of the client machine before the testing can begin

#### Client Setup:
1. On the client machine, run the `full-oqs-provider-test.sh` script

2. Select client and enter the test parameters

3. Use the IP address of the server machine

4. Begin testing and allow the script to complete

## Outputted Results
After the testing has completed, all the unparsed results will be stored in the `test-data/up-results/ops-provider/machine-x` directory. This directory contains both the TLS handshake performance and cryptographic speed test results for PQC, Hybrid-PQC, and classic ciphersuites. Results are organised by the `machine-ID` assigned during the testing setup.

These raw output files are not yet ready for interpretation or graph generation. To parse the data into a format that can be used for further analysis please refer to the **Parsing Results** section in the main `README` file.

For a detailed description of the OQS-Provider TLS performance metrics that this project can gather, what the mean, and how the un-parsed and parsed data is structured by this projects scripts, please refer to the [Performance Metrics Guide](../performance-metrics-guide.md).

> **Note:** When using more than one machine for testing, the results will only be stored on the client machine, not the server machine.

## Advanced Testing Customisation
The automated PQC TLS benchmarking tool allows users to customise certain parameters used in the testing automation process. This is particularly useful when adapting the tool to restricted networks, virtual machines, or specific performance testing conditions.

The currently supported testing customisation options are as follows:

- TCP port configuration 
- Control Signal Behaviour

### Customising Testing Suite TCP Ports
If the default TCP ports used by the benchmarking scripts are not suitable for your environment, custom ports can be specified when launching the test script. This can be done independently for the server and client by passing the following flags:

```
--server-control-port=<PORT>    Set the server control port   (1024-65535)
--client-control-port=<PORT>    Set the client control port   (1024-65535)
--s-server-port=<PORT>          Set the OpenSSL S_Server port (1024-65535)
```

**When using custom TCP ports**, please make sure the same values are provided to both the server and client instances, otherwise the testing will fail.

### Adjusting Control Signalling
By default, the tool uses a 0.25 second delay when sending control signals between the server and client instances. This is to avoid timing issues during the control signal exchange, which can cause testing to fail.

If the default control signalling timing behaviour is not suitable for your testing environment, you can customise the control signal sleep time or disable it entirely when executing the `full-oqs-provider-test.sh` script. You can adjust this by including the following flags:

```
--control-sleep-time=<TIME>     Set the control sleep time in seconds (integer or float)
--disable-control-sleep         Disable the control signal sleep time
```

**Please note** that the `--control-sleep-time` flag cannot be used together with the `--disable-control-sleep` flag.

## Useful External Documentation
- [OQS-Provider Webpage](https://openquantumsafe.org/applications/tls.html#oqs-openssl-provider)
- [OQS-Provider GitHub Page](https://github.com/open-quantum-safe/oqs-provider)
- [Latest OQS-Provider Release Notes](https://github.com/open-quantum-safe/oqs-provider/blob/main/RELEASE.md)
- [OQS Benchmarking Webpage](https://openquantumsafe.org/benchmarking/)
- [OQS Profiling Project](https://openquantumsafe.org/benchmarking/)
- [OpenSSL(3.4.1) Documentation](https://docs.openssl.org/3.4/)