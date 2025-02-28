# Automated PQC TLS Performance Benchmarking Tool Usage Guide <!-- omit from toc --> 

## Contents <!-- omit from toc --> 
- [Overview](#overview)
- [Getting Started](#getting-started)
  - [Ensuring Access to Control Signal Ports in Firewalls](#ensuring-access-to-control-signal-ports-in-firewalls)
  - [Generating Required Certificates and Private Keys](#generating-required-certificates-and-private-keys)
  - [Testing Tool Execution](#testing-tool-execution)
  - [Testing Options](#testing-options)
  - [Single Machine Testing](#single-machine-testing)
  - [Separate Server and Client Machine Testing](#separate-server-and-client-machine-testing)
- [Outputted Results](#outputted-results)
- [Included Testing Scripts](#included-testing-scripts)
- [Useful Documentation](#useful-documentation)

## Overview
This tool allows for the automatic testing of PQC TLS 1.3 handshake performance and algorithmic efficiency when integrated within the OpenSSL library through the OQS-Provider. It tests empty TLS handshakes using varying combinations of PQC and Hybrid-PQC algorithms for authentication and KEMs. Furthermore, the testing tools conduct speed tests which evaluate PQC algorithmic performance when integrated within the OpenSSL library using the Liboqs library. The automated tools also perform benchmarking for classic cryptographic algorithms to provide a comparative baseline.

The tests can be conducted on either a single machine or across two machines connected via a physical or virtual network.

### Supported Hardware <!-- omit from toc --> 
The automated testing tool is currently only supported on the following devices:

- x86 Linux Machines using a Debian based operating system
- ARM Linux devices using a 64-bit Debian based Operating System

## Getting Started
To begin testing the performance of PQC algorithms when integrated within TLS, there are various steps that must be completed and they differ depending on whether a single machine or two machines are being used. Please fully review this section before conducting the tests to ensure all configurations are correct.

The scripts required for conducting the automated testing are stored in the `scripts/test-scripts` directory which can be found within the project's root directory.

### Ensuring Access to Control Signal Ports in Firewalls
Before running the various scripts for the automated TLS performance benchmarking, it is first crucial to ensure the testing environment allows communications over the required control signalling ports. These ports are used within the automated Bash scripts to coordinate TLS testing between the server and client machines, including when testing on localhost.

By default, the ports used for control signalling are as follows:
- **Server TCP Port**: 12345
- **Client TCP Port**: 12346

Please ensure the firewall on the testing devices, alongside any firewalls placed between the server and client machines, allow communications on the ports specified above before continuing with the rest of the instructions.

If needed, these port numbers can be changed directly in the `oqsprovider-test-server.sh` and `oqsprovider-test-client.sh` bash scripts. This can be done by modifying the source and destination port values supplied to the nc commands in the `control_signal` function within these scripts. 

> **Note:** Future versions of the repository will facilitate the option to supply custom ports to the testing scripts during setup to reduce the need to edit the script files if the default ports are not suitable.

### Generating Required Certificates and Private Keys
It is necessary to first generate the required server certificate and private key files needed for the TLS performance testing tools before running the automated testing. This can be done by executing the following command from within the `scripts/testing-scripts` directory:

```
./oqsprovider-generate-keys.sh
```

This will generate the certificates and private keys and output them to the `test-data/keys` directory in the project's root directory. **If testing performance over a physical/virtual network using two machines, the keys directory will need to be transferred to the second testing machine as well.**

### Testing Tool Execution
To start the automated testing tool, open a terminal in the directory containing the Full PQC TLS Test tool and run the following command:

```
./full-oqs-provider-test.sh
```

**Please refer to the Testing Options section before beginning testing to ensure all configurations are correct**

Upon executing the script, the testing tool will prompt you to enter the parameters for the test. Depending on the testing scenario, either using a single machine or separate server and client machines, different setup techniques and options will be required. 


### Testing Options
Before discussing the execution of the testing script, a list of the testing parameters used are detailed below, to provide guidance on the information needed before performing the tests:

The testing tool will prompt you to enter the parameters for the test. These parameters include:

- Machine type (server or client)
- Machine Comparison Option
- Machine Results Number (if comparison option selected)
- Number of test runs
- Duration of each TLS handshake tests (if machine is client)
- Duration of TLS speed tests (if machine is client)
- IP address of the other machine (single machine - localhost / separate machines server IP and Client IP)

### Single Machine Testing
If using a single machine for the testing, once the certificates and private keys have been generated, perform the following steps:

#### Server Setup:
1. First, execute the `full-pqc-tls-test.sh script` and select the server machine type when prompted.
   
2. Follow the prompts to enter the test parameters. When asked for the other machine's IP, use the localhost address (127.0.0.1).

3. Ensure the server setup is complete and ready before proceeding to the client setup.

#### Client Setup:
1. Ensure the server script is active and listening, this can be seen in the first terminals output.
   
2. Open a separate terminal and execute the `full-pqc-tls-test.sh script` again.
   
3. Select the client machine type when prompted.
   
4. Follow the prompts to enter the test parameters. When asked for the other machine's IP, use the localhost address (127.0.0.1).

### Separate Server and Client Machine Testing
When utilising two separate machines for testing, one machine will be set up as the server and the other as the client. Before initiating testing, ensure that both machines are properly set up and have the required certificates and keys as discussed previously. The server machine should be fully set up and ready before activating the client machine.

#### Server Machine Setup:
1. Initiate the test server by executing the `full-pqc-tls-test.sh script`.

2. When prompted, select the server machine type.

3. Follow the prompts to enter the test parameters.

4. When asked for the other machine's IP, provide the IP address of the client machine.

#### Client Setup:
1. Ensure the server script is active and listening, this can be seen in the first terminals output.

2. Initiate the test client by executing the `full-pqc-tls-test.sh script`.
   
3. Follow the prompts to enter the test parameters.

4. When asked for the other machine's IP, provide the IP address of the server machine.

## Outputted Results
The results from the Full PQC TLS Test will be stored in the `test-data/up-results/ops-provider/machine-x` directory, which can be found within the code's root directory. The results include handshake and speed test results for both PQC and classic ciphersuites. This directory is used to store all of the unparsed results from the automated testing tools.

However, the data stored is not yet ready for interpretation or graph generation. To parse the data into a format that can be used for further analysis please refer to the [parsing results](../../README.md) section within the readme file.

> **Note:** When using more than one machine for testing, the results will only be stored on the client machine, not the server machine.

## Included Testing Scripts
The Full PQC TLS Test tool uses several scripts to perform the TLS handshake tests. These include:

- oqsprovider-test-server.sh
- oqsprovider-test-client.sh
- oqsprovider-test-speed.sh
- oqsprovider-generate-keys.sh

### oqsprovider-test-server.sh: <!-- omit from toc --> 
This script sets up and runs the server-side operations for the TLS handshake tests. It performs handshake tests for various combinations of PQC signature algorithms and KEM algorithms, as well as classical handshake tests. The script includes error handling to deal with test failures and will coordinate a reattempt with the client. The script also skips tests when both the signature and KEM algorithms are classical.

### oqsprovider-test-client.sh: <!-- omit from toc --> 
This script is responsible for client-side operations for the TLS handshake tests. It performs the client-side handshake operations and checks the test status. If the test fails, it sends a signal to the server to restart the test. The script also skips tests when both the signature and KEM algorithms are classical.

### oqsprovider-test-speed.sh: <!-- omit from toc --> 
This script performs speed tests for the PQC algorithmic operations when integrated into the OpenSSL library. It performs these tests for both PQC and classic and stores the results in a specific directory.

### oqsprovider-generate-keys.sh: <!-- omit from toc --> 
This script generates the necessary PQC and classical certificates and  private keys needed for the TLS handshake tests. It creates a new key for each PQC signature algorithm and each ECC curve.

These scripts together enable the execution of the Full PQC TLS Test, with each one handling a specific aspect of the process. They are designed to work together seamlessly, with different scripts signalling each other as needed to coordinate the process.

## Useful Documentation
- [OQS-Provider Webpage](https://openquantumsafe.org/applications/tls.html#oqs-openssl-provider)
- [OQS-Provider GitHub Page](https://github.com/open-quantum-safe/oqs-provider)
- [Latest OQS-Provider Release Notes](https://github.com/open-quantum-safe/oqs-provider/blob/main/RELEASE.md)
- [OQS Benchmarking Webpage](https://openquantumsafe.org/benchmarking/)
- [OQS Profiling Project](https://openquantumsafe.org/benchmarking/)
- [OpenSSL(3.4.1) Documentation](https://docs.openssl.org/3.4/)
