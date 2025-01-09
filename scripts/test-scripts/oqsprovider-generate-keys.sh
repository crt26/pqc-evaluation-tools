#!/bin/bash

# Copyright (c) 2024 Callum Turino
# SPDX-License-Identifier: MIT

# This script is used to generate all the certificates and keys needed for the TLS benchmarking tests, this includes creating the
# CA cert and keys, creating a signing requests for the CA, and then signing the certs and keys for the TLS test.
# The keys must then be copied to the client machine, so that each machine has a copy for the tests. 
# This script will  create all the PQC and classic certs and keys needed for the TLS handshake benchmarking tests.

#-------------------------------------------------------------------------------------------------------------------------------
function setup_base_env() {
    # Function for setting up the basic global variables for the test suite. This includes setting the root directory
    # and the global library paths for the test suite. The function establishes the root path by determining the path of the script and 
    # using this, determines the root directory of the project.

    # Determine directory that the script is being run from
    script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

    # Try and find the .dir_marker.tmp file to determine the root directory
    current_dir="$script_dir"

    while true; do

        # Check if the .pqc_eval_dir_marker.tmp file is present
        if [ -f "$current_dir/.pqc_eval_dir_marker.tmp" ]; then
            root_dir="$current_dir"  # Set root_dir to the directory, not including the file name
            break
        fi

        # Move up a directory and check again
        current_dir=$(dirname "$current_dir")

        # If the root directory is reached and the file is not found, exit the script
        if [ "$current_dir" == "/" ]; then
            echo -e "Root directory path file not present, please ensure the path is correct and try again."
            exit 1
        fi

    done

    # Declaring main dir path variables based on root dir
    libs_dir="$root_dir/lib"
    tmp_dir="$root_dir/tmp"
    test_data_dir="$root_dir/test-data"
    util_scripts="$root_dir/scripts/utility-scripts"

    # Declaring global library path files
    open_ssl_path="$libs_dir/openssl_3.2"
    liboqs_path="$libs_dir/liboqs"
    oqs_openssl_path="$libs_dir/oqs-openssl"

    # Exporting openssl lib path
    if [[ -d "$open_ssl_path/lib64" ]]; then
        openssl_lib_path="$open_ssl_path/lib64"
    else
        openssl_lib_path="$open_ssl_path/lib"
    fi
    export LD_LIBRARY_PATH="$openssl_lib_path:$LD_LIBRARY_PATH"

    # Declaring key storage path files
    keys_dir="$test_data_dir/keys"
    pqc_cert_dir="$keys_dir/pqc"
    classic_cert_dir="$keys_dir/classic"
    hybrid_cert_dir="$keys_dir/hybrid"

    # Declaring algorithm lists filepaths
    sig_alg_file="$test_data_dir/alg-lists/ssl-sig-algs.txt"
    hybrid_sig_alg_file="$test_data_dir/alg-lists/ssl-hybr-sig-algs.txt"

}

#-------------------------------------------------------------------------------------------------------------------------------
function get_algs() {
    # Function for reading in the signature algorithms into an array for use within the script

    # Creating algorithm list arrays for PQC and Hybrid-PQC sigs
    sig_algs=()
    while IFS= read -r line; do
        sig_algs+=("$line")
    done < $sig_alg_file

    hybrid_sig_algs=()
    while IFS= read -r line; do
        hybrid_sig_algs+=("$line")
    done < $hybrid_sig_alg_file

    # Declaring classic sigs array
    classic_sigs=( "RSA:2048" "RSA:3072" "RSA:4096" "prime256v1" "secp384r1" "secp521r1")

}

#-------------------------------------------------------------------------------------------------------------------------------
function classic_keygen() {
    # Function for generating all of the certificates and keys needed for the classic TLS benchmarking tests

    # Looping through classic sigs to generate CA/server cert and key files
    for sig in "${classic_sigs[@]}"; do

        # Modify sig name formatting if RSA
        if [[ $sig == RSA:* ]]; then 
            sig_name="${sig/:/_}"
        else
            sig_name=$sig
        fi

        # Check if signature is RSA or ECC curve and generate certs and keys accordingly
        if [[ $sig == RSA:* ]]; then

            # Generate CA cert and key alongside server cert and key for current RSA signature algorithm
            "$open_ssl_path/bin/openssl" req -x509 -new -newkey rsa:${sig#RSA:} -keyout "$classic_cert_dir/$sig_name-CA.key" \
                -out "$classic_cert_dir/$sig_name-CA.crt" -nodes -subj "/CN=oqstest CA" -days 365 -config "$open_ssl_path/openssl.cnf"

            "$open_ssl_path/bin/openssl" req -new -newkey rsa:${sig#RSA:} -keyout "$classic_cert_dir/$sig_name-srv.key" \
                -out "$classic_cert_dir/$sig_name-srv.csr" -nodes -subj "/CN=oqstest server" -config "$open_ssl_path/openssl.cnf"
            
            "$open_ssl_path/bin/openssl" x509 -req -in "$classic_cert_dir/$sig_name-srv.csr" \
                -out "$classic_cert_dir/$sig_name-srv.crt" -CA "$classic_cert_dir/$sig_name-CA.crt" \
                -CAkey "$classic_cert_dir/$sig_name-CA.key" -CAcreateserial -days 365

            # Remove server CSR file
            rm -f "$classic_cert_dir/$sig_name-srv.csr"

        else

            # Generate ECC CA key and cert files
            "$open_ssl_path/bin/openssl" ecparam -name $sig -genkey -out "$classic_cert_dir/${sig_name}-CA.key"

            "$open_ssl_path/bin/openssl" req -x509 -new -key "$classic_cert_dir/${sig_name}-CA.key" \
                -out "$classic_cert_dir/${sig_name}-CA.crt" -nodes -subj "/CN=oqstest CA" -days 365 -config "$open_ssl_path/openssl.cnf"

            # Generate server ECC key and CSR
            "$open_ssl_path/bin/openssl" ecparam -name $sig -genkey -out "$classic_cert_dir/${sig_name}-srv.key"

            "$open_ssl_path/bin/openssl" req -new -key "$classic_cert_dir/${sig_name}-srv.key" \
                -out "$classic_cert_dir/${sig_name}-srv.csr" -nodes -subj "/CN=oqstest server" -config "$open_ssl_path/openssl.cnf"

            # Sign server CSR with ECC CA cert
            "$open_ssl_path/bin/openssl" x509 -req -in "$classic_cert_dir/${sig_name}-srv.csr" \
                -out "$classic_cert_dir/${sig_name}-srv.crt" -CA "$classic_cert_dir/${sig_name}-CA.crt" \
                -CAkey "$classic_cert_dir/${sig_name}-CA.key" -CAcreateserial -days 365

            # Remove server CSR file
            rm -f "$classic_cert_dir/${sig_name}-srv.csr"

        fi

    done

}

#-------------------------------------------------------------------------------------------------------------------------------
function pqc_keygen() {
    # Function for generating all of the certs and keys needed for the PQC TLS benchmarking tests

    # Generate a certificate and key for PQC tests
    for sig in "${sig_algs[@]}"; do

        # Generate CA cert and key alongside server cert and key for current PQC signature algorithm
        "$open_ssl_path/bin/openssl" req -x509 -new -newkey $sig -keyout "$pqc_cert_dir/$sig-CA.key" \
            -out "$pqc_cert_dir/$sig-CA.crt" -nodes -subj "/CN=oqstest $sig CA" -days 365 -config "$open_ssl_path/openssl.cnf"

        "$open_ssl_path/bin/openssl" req -new -newkey $sig -keyout "$pqc_cert_dir/$sig-srv.key" \
            -out "$pqc_cert_dir/$sig-srv.csr" -nodes -subj "/CN=oqstest $sig server" -config "$open_ssl_path/openssl.cnf"

        "$open_ssl_path/bin/openssl" x509 -req -in "$pqc_cert_dir/$sig-srv.csr" \
            -out "$pqc_cert_dir/$sig-srv.crt" -CA "$pqc_cert_dir/$sig-CA.crt" -CAkey "$pqc_cert_dir/$sig-CA.key" -CAcreateserial -days 365
    
    done

}

#-------------------------------------------------------------------------------------------------------------------------------
function hybrid_pqc_keygen() {
    # Function for generating all of the certs and keys needed for the Hybrid-PQC TLS benchmarking tests

    # Looping through Hybrid-PQC sigs to generate CA/server cert and key files
    for sig in "${hybrid_sig_algs[@]}"; do

        # Generate CA cert and key alongside server cert and key for current Hybrid-PQC signature algorithm
        "$open_ssl_path/bin/openssl" req -x509 -new -newkey $sig -keyout "$hybrid_cert_dir/$sig-CA.key" \
            -out "$hybrid_cert_dir/$sig-CA.crt" -nodes -subj "/CN=oqstest $sig CA" -days 365 -config "$open_ssl_path/openssl.cnf"

        "$open_ssl_path/bin/openssl" req -new -newkey $sig -keyout "$hybrid_cert_dir/$sig-srv.key" \
            -out "$hybrid_cert_dir/$sig-srv.csr" -nodes -subj "/CN=oqstest $sig server" -config "$open_ssl_path/openssl.cnf"

        "$open_ssl_path/bin/openssl" x509 -req -in "$hybrid_cert_dir/$sig-srv.csr" \
            -out "$hybrid_cert_dir/$sig-srv.crt" -CA "$hybrid_cert_dir/$sig-CA.crt" -CAkey "$hybrid_cert_dir/$sig-CA.key" -CAcreateserial -days 365

    done
}

#-------------------------------------------------------------------------------------------------------------------------------
function main() {
    # Main function which controls the cert and key generation process for the various TLS benchmarking tests

    # Setting up the base environment for the test suite
    setup_base_env

    # Creating the algorithm arrays for the generation of certs and keys
    get_algs

    # Modifying the OpenSSL conf file to temporarily remove the default groups configuration
    "$util_scripts/configure-openssl-cnf.sh" 0

    # Removing old keys if present and creating key directories
    if [ -d "$keys_dir" ]; then
        rm -rf "$keys_dir"
    fi
    mkdir -p $pqc_cert_dir && mkdir -p $classic_cert_dir && mkdir -p $hybrid_cert_dir

    # Generating certs and keys for classic ciphersuite tests
    echo -e "\nGenerating certs and keys for classic ciphersuite tests:"
    classic_keygen

    # Generating certs and keys for PQC tests
    echo -e "\nGenerating certs and keys for PQC tests:"
    pqc_keygen

    # Generating certs and keys for Hybrid-PQC tests
    echo -e "\nGenerating certs and keys for Hybrid-PQC tests:"
    hybrid_pqc_keygen

    # Restoring OpenSSL conf file to have configuration needed for testing scripts
    "$util_scripts/configure-openssl-cnf.sh" 1

}
main
