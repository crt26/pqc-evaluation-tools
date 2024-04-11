#!/bin/bash

#Copyright (c) 2023 Callum Turino
#SPDX-License-Identifier: MIT

# Script for testing the computational efficiency of the PQC algorithms when integrated into OpenSSL. The script will
# take in the test parameters from the OQS-OpenSSL test control script and gather the speed metrics, assigning the results the
# specified machine number

#------------------------------------------------------------------------------
# Declaring directory path variables
current_dir=$(pwd)
root_dir=$(dirname "$current_dir")
device_name=$(hostname)
keys_dir="$root_dir/keys"
build_dir="$root_dir/builds/oqs-openssl-build/openssl"

# Declaring algorithm lists filepaths
sig_alg_file="$root_dir/alg-lists/ssl-speed-sig-algs.txt"
kem_alg_file="$root_dir/alg-lists/ssl-speed-kem-algs.txt"

# Declaring output dir
speed_output_dir="$root_dir/up-results/openssl/speed-tests"

#------------------------------------------------------------------------------
function get_algs() {
    # Function for reading in the various algorithms into an array for use within the script

    # Creating algorithm list arrays

    # Kem algorithms
    kem_algs=()
    while IFS= read -r line; do
        kem_algs+=("$line")
    done < $kem_alg_file

    # Sig algorithms
    sig_algs=()
    while IFS= read -r line; do
        sig_algs+=("$line")
    done < $sig_alg_file

}

#------------------------------------------------------------------------------
function get_options() {
    # Function for reading in the test parameters which were specified within the OQS-OpenSSL
    # test control script

    # Getting in the test time parameter
    if [ -f "$root_dir/tmp/tls_speed_time.txt" ]; then

        # Read the run number value from the tmp file
        opt1_file_input=$(<"$root_dir/tmp/tls_speed_time.txt")

        # Check if the run number value is a valid
        if [[ $opt1_file_input =~ ^[0-9]+$ ]]; then
            # Store the value as an integer variable
            tls_speed_time=$opt1_file_input
        else
            echo "Invalid run number value, please ensure value is correct when starting test"
            exit 1
        fi

    else
        echo "Run number file not found, please ensure run number file is present in repo tmp directory"
        exit 1
    
    fi

}

#------------------------------------------------------------------------------
function main() {
    # Main function which controls testing scripts which are called for TLS
    # speed performance test

    # Getting test parameters
    get_algs
    get_test_options

    # Joining the elements of algorithm arrays into a string variable to create test parameter
    kem_algs_string="${kem_algs[@]}"
    sig_algs_string="${sig_algs[@]}"

    # Creating output dirs and removing old if needed
    if [ -d $speed_output_dir ]; then
        rm -rf $speed_output_dir
    fi
    mkdir -p $speed_output_dir

    # Performing TLS speed tests
    for run_num in {1..15}; do

        # Creating output names for current run
        kem_output_filename="$speed_output_dir/ssl-speed-kem-$run_num.txt"
        sig_output_filename="$speed_output_dir/ssl-speed-sig-$run_num.txt"

        # Performing the speed tests for sig and kem algs
        "$build_dir/apps/openssl" speed -seconds $tls_speed_time $kem_algs_string > $kem_output_filename
        "$build_dir/apps/openssl" speed -seconds $tls_speed_time $sig_algs_string > $sig_output_filename
    
    done

}
main