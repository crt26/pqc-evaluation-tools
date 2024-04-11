#!/bin/bash

#Copyright (c) 2023 Callum Turino
#SPDX-License-Identifier: MIT

# Script for controlling the Liboqs benchmark testing, it takes in the test parameters and call the relevant test scripts

#------------------------------------------------------------------------------
# Declaring global main dir path variables
root_dir=$(pwd)
libs_dir="$root_dir/lib"
tmp_dir="$root_dir/tmp"
test_data_dir="$root_dir/test-data"

# Declaring global library path files
open_ssl_path="$libs_dir/openssl_3.2"
liboqs_path="$libs_dir/liboqs"
oqs_openssl_path="$libs_dir/oqs-openssl"

# Declaring various test result directories
machine_speed_results=""
machine_mem_results=""
kem_mem_results=""
sig_mem_results=""

# Declaring global test parameter variables
machine_num=""
number_of_runs=0

# "$test_data_dir"/up-results/liboqs/mem-results/
# "$test_data_dir"/up-results/liboqs/mem-results/kem-mem-metrics/ && mkdir -p "$root_dir"/up-results/liboqs/mem-results/sig-mem-metrics/

#------------------------------------------------------------------------------
function set_result_paths() {

    # Setting results path based on assigned machine number for results
    machine_results_path="$test_data_dir/up-results/liboqs/$machine_num"
    machine_speed_results="$machine_results_path/speed-results"
    machine_mem_results="$machine_results_path/mem-results"
    kem_mem_results="$machine_mem_results/kem-mem-metrics"
    sig_mem_results="$machine_mem_results/sig-mem-metrics"

    # # Set Liboqs dir path
    # test_dir="$liboqs_path/build/tests"

}

function main() {
    rm -rf "$test_data_dir/up-results"
    rm -rf "$test_data_dir/keys"
    rm -rf "$tmp_dir/*"
}
main