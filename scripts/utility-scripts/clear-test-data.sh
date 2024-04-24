#!/bin/bash

#Copyright (c) 2023 Callum Turino
#SPDX-License-Identifier: MIT

# Script for controlling the Liboqs benchmark testing, it takes in the test parameters and call the relevant test scripts

#------------------------------------------------------------------------------
# Declaring global main dir path variables
root_dir=$(cd "$PWD"/../.. && pwd)
libs_dir="$root_dir/lib"
tmp_dir="$root_dir/tmp"
test_data_dir="$root_dir/test-data"
test_scripts_path="$root_dir/scripts/test-scripts"


# Declaring global library path files
open_ssl_path="$libs_dir/openssl_3.2"
liboqs_path="$libs_dir/liboqs"
oqs_openssl_path="$libs_dir/oqs-openssl"
# Declaring global test parameter variables
machine_num=""
number_of_runs=0

#------------------------------------------------------------------------------
function main() {

    echo "############################"
    echo "Clear Results Utility Script"
    echo -e "############################\n"


    # Remove all result directories and test-data files

    rm -rf "$test_data_dir/results"
    rm -rf "$test_data_dir/up-results"
    rm -rf "$test_data_dir/keys"
    rm -rf "$tmp_dir/*"


    echo "All results and generated keys cleared"
    
}
main