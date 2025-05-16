#!/bin/bash

# Copyright (c) 2023-2025 Callum Turino
# SPDX-License-Identifier: MIT

# Script executed from the client machine to benchmark the computational performance of PQC, Hybrid-PQC, and 
# Classic digital signature and KEM algorithms integrated into OpenSSL 3.5.0 via the OQS-Provider. It receives 
# test parameters from the main OQS-Provider test control script and runs OpenSSL's speed utility to collect
# per-algorithm timing metrics. Results are stored in machine-specific directories under the appropriate 
# TLS test type, using the assigned machine ID exported by the full-pqc-tls-test.sh script.

#-------------------------------------------------------------------------------------------------------------------------------
function setup_test_env() {
    # Function for setting up the global environment variables for the test suite. This includes determining the root directory 
    # by tracing the script's location, and configuring paths for libraries, test data, and temporary files. The function
    # also handles the creation of the algorithm list arrays and the output directories for the test results.

    # Determine the directory that the script is being executed from
    script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

    # Try and find the .dir_marker.tmp file to determine the project's root directory
    current_dir="$script_dir"

    # Continue moving up the directory tree until the .pqc_eval_dir_marker.tmp file is found
    while true; do

        # Check if the .pqc_eval_dir_marker.tmp file is present
        if [ -f "$current_dir/.pqc_eval_dir_marker.tmp" ]; then
            root_dir="$current_dir"  # Set root_dir to the directory, not including the file name
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
    test_scripts_path="$root_dir/scripts/test-scripts"
    util_scripts="$root_dir/scripts/utility-scripts"

    # Declare the global library directory path variables
    openssl_path="$libs_dir/openssl_3.5.0"
    oqs_provider_path="$libs_dir/oqs-provider"
    provider_path="$oqs_provider_path/lib"

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

    # Set the alg-list txt filepaths
    kem_alg_file="$test_data_dir/alg-lists/tls-kem-algs.txt"
    sig_alg_file="$test_data_dir/alg-lists/tls-sig-algs.txt"
    hybrid_kem_alg_file="$test_data_dir/alg-lists/tls-hybr-kem-algs.txt"
    hybrid_sig_alg_file="$test_data_dir/alg-lists/tls-hybr-sig-algs.txt"

    # Create the PQC KEM and digital signature algorithm list arrays
    kem_algs=()
    while IFS= read -r line; do
        kem_algs+=("$line")
    done < $kem_alg_file

    sig_algs=()
    while IFS= read -r line; do
        sig_algs+=("$line")
    done < $sig_alg_file

    # Create the Hybrid-PQC KEM and digital signature algorithm list arrays
    hybrid_kem_algs=()
    while IFS= read -r line; do
        hybrid_kem_algs+=("$line")
    done < $hybrid_kem_alg_file

    hybrid_sig_algs=()
    while IFS= read -r line; do
        hybrid_sig_algs+=("$line")
    done < $hybrid_sig_alg_file

    # Create the result output directories and removing old if needed
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
function tls_speed_test() {
    # Function for running the TLS speed tests for the various algorithm types. It uses the OpenSSL s_speed utility to benchmark
    # the performance of the specified algorithms when integrated into OpenSSL 3.5.0 via the OQS-Provider.

    # Joining the elements of algorithm arrays into a string variable to create test parameter
    kem_algs_string="${kem_algs[@]}"
    sig_algs_string="${sig_algs[@]}"
    hybrid_kem_algs_string="${hybrid_kem_algs[@]}"
    hybrid_sig_algs_string="${hybrid_sig_algs[@]}"

    # Perform the TLS speed tests for the specified number of runs
    for run_num in $(seq 1 $NUM_RUN); do

        # Create the result output filenames for current run
        kem_output_filename="$PQC_SPEED/tls-speed-kem-$run_num.txt"
        sig_output_filename="$PQC_SPEED/tls-speed-sig-$run_num.txt"
        hybrid_kem_output_filename="$HYBRID_SPEED/tls-speed-hybrid-kem-$run_num.txt"
        hybrid_sig_output_filename="$HYBRID_SPEED/tls-speed-hybrid-sig-$run_num.txt"
        classic_output_filename="$CLASSIC_SPEED/tls-speed-classic-$run_num.txt"

        # Perform the PQC KEM algorithms speed tests
        "$openssl_path/bin/openssl" speed \
            -seconds $TIME_NUM \
            -provider-path $provider_path \
            -provider oqsprovider  \
            $kem_algs_string > $kem_output_filename

        # Perform the PQC digital signature algorithms speed tests
        "$openssl_path/bin/openssl" speed \
            -seconds $TIME_NUM \
            -provider-path $provider_path \
            -provider oqsprovider \
            $sig_algs_string > $sig_output_filename

        # Perform the Hybrid-PQC KEM algorithms speed tests
        "$openssl_path/bin/openssl" speed \
            -seconds $TIME_NUM \
            -provider-path $provider_path \
            -provider oqsprovider \
            $hybrid_kem_algs_string > $hybrid_kem_output_filename

        # Perform the Hybrid-PQC digital signature algorithms speed tests
        "$openssl_path/bin/openssl" speed \
            -seconds $TIME_NUM \
            -provider-path $provider_path \
            -provider oqsprovider \
            $hybrid_sig_algs_string > $hybrid_sig_output_filename

    done

}

#-------------------------------------------------------------------------------------------------------------------------------
function main() {
    # Main function for controlling the TLS speed performance tests

    # Setup the base environment for the test suite
    setup_test_env

    # Modify the OpenSSL conf file to temporarily remove the default groups configuration
    if ! "$util_scripts/configure-openssl-cnf.sh" 0; then
        echo "[ERROR] - Failed to modify OpenSSL configuration."
        exit 1
    fi

    # Run the TLS speed tests for the various algorithm types
    tls_speed_test

    # Restore the OpenSSL conf file to have the configuration needed for the testing scripts
    if ! "$util_scripts/configure-openssl-cnf.sh" 1; then
        echo "[ERROR] - Failed to modify OpenSSL configuration."
        exit 1
    fi

}
main