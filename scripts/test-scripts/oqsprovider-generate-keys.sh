#!/bin/bash

# Copyright (c) 2023-2025 Callum Turino
# SPDX-License-Identifier: MIT

# Script for generating all the server certificates and keys required for the TLS handshake benchmarking suite. 
# It creates classic, post-quantum, and hybrid-pqc certificates by generating CA keys, certificate signing requests, 
# and signed server certificates using OpenSSL 3.4.1. The resulting key material must be copied to the client machine #
# unless both client and server run on the same system.

#-------------------------------------------------------------------------------------------------------------------------------
function setup_base_env() {
    # Function for setting up the basic global variables for the script. This includes setting the root directory, the global 
    # library paths for the test suite, and creating the algorithm arrays. The function establishes the root path by determining 
    # the path of the script and using this, determines the root directory of the project.

    # Determine the directory that the script is being run from
    script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

    # Try and find the .dir_marker.tmp file to determine the project's root directory
    current_dir="$script_dir"

    # Continue moving up the directory tree until the .pqc_eval_dir_marker.tmp file is found
    while true; do

        # Check if the .pqc_eval_dir_marker.tmp file is present
        if [ -f "$current_dir/.pqc_eval_dir_marker.tmp" ]; then
            root_dir="$current_dir"
            break
        fi

        # Move up a directory and store the new path
        current_dir=$(dirname "$current_dir")

        # If the system's root directory is reached and the file is not found, exit the script
        if [ "$current_dir" == "/" ]; then
            echo -e "Root directory path file not present, please ensure the path is correct and try again."
            exit 1
        fi

    done

    # Declare the main directory path variables based on the project's root dir
    libs_dir="$root_dir/lib"
    tmp_dir="$root_dir/tmp"
    test_data_dir="$root_dir/test-data"
    util_scripts="$root_dir/scripts/utility-scripts"

    # Declare the global library directory path variables
    openssl_path="$libs_dir/openssl_3.4"
    oqs_provider_path="$libs_dir/oqs-provider"

    # Ensure that the OQS-Provider and OpenSSL libraries are present before proceeding
    if [ ! -d "$oqs_provider_path" ]; then
        echo "[ERROR] - OQS-Provider library not found in $libs_dir"
        exit 1
    
    elif [ ! -d "$openssl_path" ]; then
        echo "[ERROR] - OpenSSL library not found in $libs_dir"
        exit 1
    fi

    # Check the OpenSSL library directory path
    if [[ -d "$openssl_path/lib64" ]]; then
        openssl_lib_path="$openssl_path/lib64"
    else
        openssl_lib_path="$openssl_path/lib"
    fi

    # Export the OpenSSL library filepath
    export LD_LIBRARY_PATH="$openssl_lib_path:$LD_LIBRARY_PATH"

    # Declare global key storage directory paths
    keys_dir="$test_data_dir/keys"
    pqc_cert_dir="$keys_dir/pqc"
    classic_cert_dir="$keys_dir/classic"
    hybrid_cert_dir="$keys_dir/hybrid"

    # Set the alg-list txt filepaths
    sig_alg_file="$test_data_dir/alg-lists/tls-sig-algs.txt"
    hybrid_sig_alg_file="$test_data_dir/alg-lists/tls-hybr-sig-algs.txt"

    # Create the PQC and Hybrid-PQC digital signature algorithm list arrays
    sig_algs=()
    while IFS= read -r line; do
        sig_algs+=("$line")
    done < $sig_alg_file

    hybrid_sig_algs=()
    while IFS= read -r line; do
        hybrid_sig_algs+=("$line")
    done < $hybrid_sig_alg_file

    # Declaring classic digital signature algorithms array
    classic_sigs=( "RSA:2048" "RSA:3072" "RSA:4096" "prime256v1" "secp384r1" "secp521r1")

}

#-------------------------------------------------------------------------------------------------------------------------------
function classic_keygen() {
    # Function for generating all of the server certificates and private-keys needed for the classic TLS benchmarking tests

    # Loop through the classic digital signature to generate the CA/server certs and private-key files
    for sig in "${classic_sigs[@]}"; do

        # Modify the signature name formatting if RSA
        if [[ $sig == RSA:* ]]; then 
            sig_name="${sig/:/_}"
        else
            sig_name=$sig
        fi

        # Check if the signature is RSA or an ECC curve and generate the certs/keys accordingly
        if [[ $sig == RSA:* ]]; then

            # Generate the CA cert and key for the current RSA signature algorithm
            "$openssl_path/bin/openssl" req \
                -x509 \
                -new \
                -newkey rsa:${sig#RSA:} \
                -keyout "$classic_cert_dir/$sig_name-CA.key" \
                -out "$classic_cert_dir/$sig_name-CA.crt" \
                -nodes \
                -subj "/CN=oqstest CA" \
                -days 365 \
                -config "$openssl_path/openssl.cnf"

            # Generate the server certificate signing request for the current RSA signature algorithm
            "$openssl_path/bin/openssl" req \
                -new \
                -newkey rsa:${sig#RSA:} \
                -keyout "$classic_cert_dir/$sig_name-srv.key" \
                -out "$classic_cert_dir/$sig_name-srv.csr" \
                -nodes \
                -subj "/CN=oqstest server" \
                -config "$openssl_path/openssl.cnf"
            
            # Sign the server CSR with the RSA CA cert
            "$openssl_path/bin/openssl" x509 \
                -req \
                -in "$classic_cert_dir/$sig_name-srv.csr" \
                -out "$classic_cert_dir/$sig_name-srv.crt" \
                -CA "$classic_cert_dir/$sig_name-CA.crt" \
                -CAkey "$classic_cert_dir/$sig_name-CA.key" \
                -CAcreateserial \
                -days 365

            # Remove the server CSR file
            rm -f "$classic_cert_dir/$sig_name-srv.csr"

        else

            # Generate the ECC CA private key using the specified curve
            "$openssl_path/bin/openssl" ecparam \
                -name $sig \
                -genkey \
                -out "$classic_cert_dir/${sig_name}-CA.key"

            # Generate the ECC CA certificate using the generated key
            "$openssl_path/bin/openssl" req \
                -x509 \
                -new \
                -key "$classic_cert_dir/${sig_name}-CA.key" \
                -out "$classic_cert_dir/${sig_name}-CA.crt" \
                -nodes \
                -subj "/CN=oqstest CA" \
                -days 365 \
                -config "$openssl_path/openssl.cnf"

            # Generate the ECC server private key using the same curve
            "$openssl_path/bin/openssl" ecparam \
                -name $sig \
                -genkey \
                -out "$classic_cert_dir/${sig_name}-srv.key"

            # Generate the certificate signing request for the server using the ECC private key
            "$openssl_path/bin/openssl" req \
                -new \
                -key "$classic_cert_dir/${sig_name}-srv.key" \
                -out "$classic_cert_dir/${sig_name}-srv.csr" \
                -nodes \
                -subj "/CN=oqstest server" \
                -config "$openssl_path/openssl.cnf"

            # Sign the server CSR using the ECC CA certificate and key
            "$openssl_path/bin/openssl" x509 \
                -req \
                -in "$classic_cert_dir/${sig_name}-srv.csr" \
                -out "$classic_cert_dir/${sig_name}-srv.crt" \
                -CA "$classic_cert_dir/${sig_name}-CA.crt" \
                -CAkey "$classic_cert_dir/${sig_name}-CA.key" \
                -CAcreateserial \
                -days 365

            # Remove the server CSR file
            rm -f "$classic_cert_dir/${sig_name}-srv.csr"

        fi

    done

}

#-------------------------------------------------------------------------------------------------------------------------------
function pqc_keygen() {
    # Function for generating all of the server certificates and private-keys needed for the PQC TLS benchmarking tests

    # Loop through the PQC digital signature to generate the CA/server certs and private-key files
    for sig in "${sig_algs[@]}"; do

        # Generate the CA certificate and private key for the current PQC signature algorithm
        "$openssl_path/bin/openssl" req \
            -x509 \
            -new \
            -newkey $sig \
            -keyout "$pqc_cert_dir/$sig-CA.key" \
            -out "$pqc_cert_dir/$sig-CA.crt" \
            -nodes \
            -subj "/CN=oqstest $sig CA" \
            -days 365 \
            -config "$openssl_path/openssl.cnf"

        # Generate the server certificate signing request for the current PQC signature algorithm
        "$openssl_path/bin/openssl" req \
            -new \
            -newkey $sig \
            -keyout "$pqc_cert_dir/$sig-srv.key" \
            -out "$pqc_cert_dir/$sig-srv.csr" \
            -nodes \
            -subj "/CN=oqstest $sig server" \
            -config "$openssl_path/openssl.cnf"

        # Sign the server CSR using the PQC CA certificate and key
        "$openssl_path/bin/openssl" x509 -req -in "$pqc_cert_dir/$sig-srv.csr" \
            -out "$pqc_cert_dir/$sig-srv.crt" -CA "$pqc_cert_dir/$sig-CA.crt" -CAkey "$pqc_cert_dir/$sig-CA.key" -CAcreateserial -days 365

        # Remove the server CSR file
        rm -f "$pqc_cert_dir/$sig-srv.csr"
    
    done

}

#-------------------------------------------------------------------------------------------------------------------------------
function hybrid_pqc_keygen() {
    # Function for generating all of the server certificates and private-keys needed for the Hybrid-PQC TLS benchmarking tests

    # Loop through the Hybrid-PQC digital signature to generate the CA/server certs and private-key files
    for sig in "${hybrid_sig_algs[@]}"; do

        # Generate the CA certificate and private key for the current Hybrid-PQC signature algorithm
        "$openssl_path/bin/openssl" req \
            -x509 \
            -new \
            -newkey $sig \
            -keyout "$hybrid_cert_dir/$sig-CA.key" \
            -out "$hybrid_cert_dir/$sig-CA.crt" \
            -nodes \
            -subj "/CN=oqstest $sig CA" \
            -days 365 \
            -config "$openssl_path/openssl.cnf"

        # Generate the server certificate signing request for the current Hybrid-PQC signature algorithm
        "$openssl_path/bin/openssl" req \
            -new \
            -newkey $sig \
            -keyout "$hybrid_cert_dir/$sig-srv.key" \
            -out "$hybrid_cert_dir/$sig-srv.csr" \
            -nodes \
            -subj "/CN=oqstest $sig server" \
            -config "$openssl_path/openssl.cnf"

        # Sign the server CSR using the Hybrid-PQC CA certificate and key
        "$openssl_path/bin/openssl" x509 \
            -req \
            -in "$hybrid_cert_dir/$sig-srv.csr" \
            -out "$hybrid_cert_dir/$sig-srv.crt" \
            -CA "$hybrid_cert_dir/$sig-CA.crt" \
            -CAkey "$hybrid_cert_dir/$sig-CA.key" \
            -CAcreateserial -days 365

        # Remove the server CSR file
        rm -f "$hybrid_cert_dir/$sig-srv.csr"

    done

}

#-------------------------------------------------------------------------------------------------------------------------------
function main() {
    # Main function for controlling the certificate and private-key generation process for the various TLS benchmarking tests

    # Output a greeting message to the terminal
    echo -e "OQS-Provider TLS Certificate Generation Script\n"

    # Setup the base environment for the script
    setup_base_env

    # Modify the OpenSSL conf file to temporarily remove the default groups configuration
    if ! "$util_scripts/configure-openssl-cnf.sh" 0; then
        echo "[ERROR] - Failed to modify OpenSSL configuration."
        exit 1
    fi

    # Remove the old keys if present and create the key storage directories
    if [ -d "$keys_dir" ]; then
        rm -rf "$keys_dir"
    fi
    mkdir -p "$pqc_cert_dir" && mkdir -p "$classic_cert_dir" && mkdir -p "$hybrid_cert_dir"

    # Generate the certs and keys for the classic ciphersuite tests
    echo -e "\nGenerating certs and keys for classic ciphersuite tests:"
    classic_keygen

    # Generate the certs and keys for the PQC tests
    echo -e "\nGenerating certs and keys for PQC tests:"
    pqc_keygen

    # Generate the certs and keys for the Hybrid-PQC tests
    echo -e "\nGenerating certs and keys for Hybrid-PQC tests:"
    hybrid_pqc_keygen

    # Restore the OpenSSL conf file to have configuration needed for testing scripts
    if ! "$util_scripts/configure-openssl-cnf.sh" 1; then
        echo "[ERROR] - Failed to modify OpenSSL configuration."
        exit 1
    fi

}
main