#!/bin/bash

# Copyright (c) 2024 Callum Turino
# SPDX-License-Identifier: MIT

# Script ran from the client machine for testing the computational efficiency of the PQC algorithms when integrated into OpenSSL. 
# The script will take in the test parameters from the OQS-Provider test control script and gather the speed metrics. The script will then
# output the results, using the assigned machine ID stored in the environment from the main full-pqc-tls-test.sh script.
# This script consists of three main tests, the PQC TLS handshake tests, Hybrid-PQC TLS handshake tests, and the Classic TLS handshake tests.

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
    test_scripts_path="$root_dir/scripts/test-scripts"
    util_scripts="$root_dir/scripts/utility-scripts"

    # Declaring global library path files
    open_ssl_path="$libs_dir/openssl_3.2"
    oqs_openssl_path="$libs_dir/oqs-provider"
    provider_path="$libs_dir/oqs-provider/lib"

    # Exporting openssl lib path
    if [[ -d "$open_ssl_path/lib64" ]]; then
        openssl_lib_path="$open_ssl_path/lib64"
    else
        openssl_lib_path="$open_ssl_path/lib"
    fi

    export LD_LIBRARY_PATH="$openssl_lib_path:$LD_LIBRARY_PATH"

    # Declaring static algorithm arrays and alg-list filepaths
    kem_alg_file="$test_data_dir/alg-lists/ssl-kem-algs.txt"
    sig_alg_file="$test_data_dir/alg-lists/ssl-sig-algs.txt"
    hybrid_kem_alg_file="$test_data_dir/alg-lists/ssl-hybr-kem-algs.txt"
    hybrid_sig_alg_file="$test_data_dir/alg-lists/ssl-hybr-sig-algs.txt"

}

#-------------------------------------------------------------------------------------------------------------------------------
function set_test_env() {
    # Function for setting up the testing environment by getting algorithms from text files and creating output dirs

    # Kem algorithms array
    kem_algs=()
    while IFS= read -r line; do
        kem_algs+=("$line")
    done < $kem_alg_file

    # Sig algorithms array
    sig_algs=()
    while IFS= read -r line; do
        sig_algs+=("$line")
    done < $sig_alg_file

    # Hybrid-PQC kem algorithms array
    hybrid_kem_algs=()
    while IFS= read -r line; do
        hybrid_kem_algs+=("$line")
    done < $hybrid_kem_alg_file

    # Hybrid-PQC sig algorithms array
    hybrid_sig_algs=()
    while IFS= read -r line; do
        hybrid_sig_algs+=("$line")
    done < $hybrid_sig_alg_file

    # Creating output dirs and removing old if needed
    if [ -d $PQC_SPEED ]; then
        rm -rf $PQC_SPEED
    fi
    mkdir -p $PQC_SPEED

    if [ -d $HYBRID_SPEED ]; then
        rm -rf $HYBRID_SPEED
    fi
    mkdir -p $HYBRID_SPEED

}

#-------------------------------------------------------------------------------------------------------------------------------
function main() {
    # Main function which controls testing scripts which are called for TLS speed performance test

    # Setting up the base environment for the test suite
    setup_base_env

    # Configure the testing environment
    set_test_env

    # Joining the elements of algorithm arrays into a string variable to create test parameter
    kem_algs_string="${kem_algs[@]}"
    sig_algs_string="${sig_algs[@]}"
    hybrid_kem_algs_string="${hybrid_kem_algs[@]}"
    hybrid_sig_algs_string="${hybrid_sig_algs[@]}"

    # Modifying the OpenSSL conf file to temporarily remove the default groups configuration
    "$util_scripts/configure-openssl-cnf.sh" 0

    # Performing TLS speed tests for the various test types
    for run_num in $(seq 1 $NUM_RUN); do

        # Creating output names for current run
        kem_output_filename="$PQC_SPEED/ssl-speed-kem-$run_num.txt"
        sig_output_filename="$PQC_SPEED/ssl-speed-sig-$run_num.txt"
        hybrid_kem_output_filename="$HYBRID_SPEED/ssl-speed-hybrid-kem-$run_num.txt"
        hybrid_sig_output_filename="$HYBRID_SPEED/ssl-speed-hybrid-sig-$run_num.txt"
        classic_output_filename="$CLASSIC_SPEED/ssl-speed-classic-$run_num.txt"

        # PQC sig and kem algs speed tests
        "$open_ssl_path/bin/openssl" speed -seconds $TIME_NUM -provider-path $provider_path -provider oqsprovider  $kem_algs_string > $kem_output_filename
        "$open_ssl_path/bin/openssl" speed -seconds $TIME_NUM -provider-path $provider_path -provider oqsprovider $sig_algs_string > $sig_output_filename

        # PQC-Hybrid sig and kem algs speed tests
        "$open_ssl_path/bin/openssl" speed -seconds $TIME_NUM -provider-path $provider_path -provider oqsprovider  $hybrid_kem_algs_string > $hybrid_kem_output_filename
        "$open_ssl_path/bin/openssl" speed -seconds $TIME_NUM -provider-path $provider_path -provider oqsprovider $hybrid_sig_algs_string > $hybrid_sig_output_filename

    done

    # Restoring OpenSSL conf file to have configuration needed for testing scripts
    "$util_scripts/configure-openssl-cnf.sh" 1

}
main