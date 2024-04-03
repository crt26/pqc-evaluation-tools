#!/bin/bash

#Copyright (c) 2023 Callum Turino
#SPDX-License-Identifier: MIT

# Script for automating the liboqs speed benchmarking tests, using the test parameters specified from the liboqs test control script

#------------------------------------------------------------------------------
# Declaring directory path variables
current_dir=$(pwd)
root_dir=$(dirname "$current_dir")
device_name=$(hostname)

#------------------------------------------------------------------------------
function initial_setup() {
    # Function for performing the initial test setup including directory management
    # and loading in testing parameters

    # Getting build directory
    if [ -d "$root_dir/builds/x86-liboqs-linux" ]; then

        # Moving directory and clearing old results
        build_dir="builds/x86-liboqs-linux" 
        cd "$root_dir"/"$build_dir"/speed-results && rm -f ./*
        cd "$root_dir"/"$build_dir"/tests

    elif [ -d "$root_dir/builds/arm-liboqs-linux" ]; then

        # Moving directory and clearing old results
        build_dir="builds/arm-liboqs-linux"
        cd "$root_dir"/"$build_dir"/speed-results && rm -f ./*
        cd "$root_dir"/"$build_dir"/tests

    else
        echo -e "No Build Directory Detected - Please Build Liboqs to proceed\n"
        exit 1
    
    fi

    # Getting the number of runs for the test
    if [ -f "$root_dir/tmp/liboqs_number_of_runs.txt" ]; then

        # Read the run number value from the tmp file
        opt1_file_input=$(<"$root_dir/tmp/liboqs_number_of_runs.txt")

        # Check if the run number value is a valid
        if [[ $opt1_file_input =~ ^[0-9]+$ ]]; then
            
            # Store the value as an integer variable
            number_of_runs=$opt1_file_input

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
    # Main function for performing the speed benchmark testing

    # Performing initial setup
    initial_setup

    # Performing liboqs CPU speed benchmarking tests

    echo "*******************"
    echo -e "\nBeginning Speed Tests\n"
    echo "*******************"

    # Performing both KEM and Digital Signature test
    cd "$root_dir"/"$build_dir"/tests

    for run_num in $(seq 1 $number_of_runs); do 

        ./speed_kem > "$root_dir/$build_dir/speed-results/test-kem-speed-$run_num.csv"
        ./speed_sig > "$root_dir/$build_dir/speed-results/test-sig-speed-$run_num.csv"

    done

    # Moving results
    mv "$root_dir"/"$build_dir"/speed-results/ "$root_dir"/up-results/liboqs/t-speed-results
    mkdir -p "$root_dir"/"$build_dir"/speed-results/
    cd "$root_dir"/test-scripts
    
}
main