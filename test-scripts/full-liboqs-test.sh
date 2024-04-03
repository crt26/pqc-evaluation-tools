#!/bin/bash

#Copyright (c) 2023 Callum Turino
#SPDX-License-Identifier: MIT

# Script for controlling the Liboqs benchmark testing, it takes in the test parameters and call the relevant test scripts

#------------------------------------------------------------------------------
# Declaring directory variables
current_dir=$(pwd)
root_dir=$(dirname "$current_dir")
device_name=$(hostname)

#------------------------------------------------------------------------------
function get_test_options() {
    # Function for getting the test parameters from the user before performing the tests

    # Getting if tests being done will compare multiple machine

    # Getting y/n input from user and storing result
    while true; do

        read -p "Do you intend to compare the results against other machines [y/n]? - " response_1
        case $response_1 in

            [Yy]* ) answer="yes"; break;;

            [Nn]* ) answer="no"; break;;

            * ) echo -e "\nPlease answer y/n\n";;
        esac
    done

    echo -e "\n"

    # Getting the machine number from the user to be used when saving results
    if [ "$answer" == "yes" ]; then

        while true; do
            read -p "What machine number would you like to assign to these results? - " response_2
            case $response_2 in

                # Asking the user to enter a number
                ''|*[!0-9]*) echo -e "\nPlease enter a number\n"; 
                continue;;

                # If a number is entered by the user it is stored for later use
                * ) machine_num="$response_2"; echo -e "\nMachine number set to $response_2 \n";
                break;;
            esac
        done
    
    else
        # Using default value
        echo -e "Using default name for saving results\n"
    fi

    # Getting the number of runs
    echo -e "\nNumber of Runs for Tests Selection"
    while true; do

        # Prompt the user to input an integer
        read -p "Enter the number of test runs required: " user_run_num

        # Check if the input is a valid integer
        if [[ $user_run_num =~ ^[0-9]+$ ]]; then

            # Store the user input
            echo $user_run_num > "$root_dir/tmp/liboqs_number_of_runs.txt"
            break
        
        else
            echo -e "Invalid input. Please enter a valid integer.\n"
        fi
    
    done

}

#------------------------------------------------------------------------------
function setup_test_suite() {
    # Function for setting up the test suite directories and removing old results if needed

    # Performing setup of test suite
    echo -e "Preparing Test Suite\n"

    # Creating unparsed results directory and clearing old results if present
    if [ -d "$root_dir/up-results" ]; then
        sudo rm -r "$root_dir"/up-results/
        mkdir -p "$root_dir"/up-results/liboqs/speed-results/
        mkdir -p "$root_dir"/up-results/liboqs/mem-results/
        mkdir -p "$root_dir"/up-results/liboqs/mem-results/kem-mem-metrics/ && mkdir -p "$root_dir"/up-results/liboqs/mem-results/sig-mem-metrics/

    else
        mkdir -p "$root_dir"/up-results/liboqs/speed-results/
        mkdir -p "$root_dir"/up-results/liboqs/mem-results/
        mkdir -p "$root_dir"/up-results/liboqs/mem-results/kem-mem-metrics/ && mkdir -p "$root_dir"/up-results/liboqs/mem-results/sig-mem-metrics/
        
    fi

}

#------------------------------------------------------------------------------
function main() {
    # Main function for controlling liboqs testing

    # Getting test options and setting up test suite
    get_test_options
    setup_test_suite

    # Performing liboqs Memory tests
    cd "$root_dir"/test-scripts
    ./liboqs-mem-test.sh

    # Performing liboqs CPU speed tests
    cd "$root_dir"/test-scripts
    ./liboqs-speed-test.sh

    # Assigning machine number to result directories if requested by the user
    machine_direc="machine-$machine_num"

    # Changing result directory names for liboqs
    mkdir -p "$root_dir"/up-results/liboqs/temp-speed-results/"$machine_direc"
    mkdir -p "$root_dir"/up-results/liboqs/mem-results/"$machine_direc"
    mv "$root_dir"/up-results/liboqs/mem-results/kem-mem-metrics "$root_dir"/up-results/liboqs/mem-results/"$machine_direc"/
    mv "$root_dir"/up-results/liboqs/mem-results/sig-mem-metrics "$root_dir"/up-results/liboqs/mem-results/"$machine_direc"/
    mv "$root_dir"/up-results/liboqs/t-speed-results/* "$root_dir"/up-results/liboqs/temp-speed-results/"$machine_direc"/
    rm -rf "$root_dir/up-results/liboqs/t-speed-results/"

}
main