#!/bin/bash

#Copyright (c) 2024 Callum Turino
#SPDX-License-Identifier: MIT

# Script for controlling the Liboqs benchmark testing, it takes in the test parameters and calls the relevant test scripts
# to perform the speed and memory benchmarking tests for included in the Liboqs library. The script also handles the storage of the results
# and ensures that the results are stored in the correct directories based on the assigned machine number.

#-------------------------------------------------------------------------------------------------------------------------------
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

#-------------------------------------------------------------------------------------------------------------------------------
function set_result_paths() {
    # Function for setting the result paths based on the assigned machine number

    # Setting results path based on assigned machine number for results
    machine_results_path="$test_data_dir/up-results/liboqs/machine-$machine_num"
    machine_speed_results="$machine_results_path/raw-speed-results"
    machine_mem_results="$machine_results_path/mem-results"
    kem_mem_results="$machine_mem_results/kem-mem-metrics"
    sig_mem_results="$machine_mem_results/sig-mem-metrics"

}

#-------------------------------------------------------------------------------------------------------------------------------
function get_machine_num() {
    # Function for getting the machine ID from the user to assign to the test results

    # Getting the machine ID from the user
    while true; do

        read -p "What machine number would you like to assign to these results? - " response
        
        case $response in

            # Asking the user to enter a number
            ''|*[!0-9]*) echo -e "Invalid value, please enter a number\n"; 
            continue;;

            # If a number is entered by the user it is stored for later use
            * ) machine_num="$response"; echo -e "\nMachine-ID set to $response \n";
            break;;

        esac

    done

}

#-------------------------------------------------------------------------------------------------------------------------------
function handle_machine_id_clash() {
    # Function for handling the clash of pre-existing machine IDs when assigning a new machine ID

    # Get user choice for handling clash
    while true; do

        # Outputting options
        echo -e "There are already results stored for Machine-ID ($machine_num), would you like to:"
        echo -e "1 - Replace old results and keep same Machine-ID"
        echo -e "2 - Assign a different machine ID"
        read -p "Enter Option: " user_response

        # Handling user response
        case $user_response in

            1)
                # Remove old results and create new directories
                echo -e "\nReplacing old results\n"
                rm -rf $machine_results_path
                mkdir -p "$machine_speed_results"
                mkdir -p "$kem_mem_results" && mkdir -p "$sig_mem_results"
                break;;

            2)
                # Getting new machine ID to be assigned to results
                echo -e "Assigning new Machine-ID for test results"
                get_machine_num

                # Setting results path based on assigned machine number for results
                set_result_paths

                # Ensuring the new ID does not have results stored
                if [ ! -d "$machine_results_path" ]; then
                    echo -e "No previous results present for Machine-ID ($machine_num), continuing test setup"
                    break
                else
                    echo "There are previous results detected for new Machine-ID value, please select different value or replace old results"
                fi
                ;;
        
        esac

    done

}

#-------------------------------------------------------------------------------------------------------------------------------
function get_test_options() {
    # Function for getting the test parameters from the user before performing the tests

    # Getting if tests being done will be compared against other machines
    while true; do

        read -p "Do you intend to compare the results against other machines [y/n]? - " response_1
        case $response_1 in

            [Yy]* ) 
                get_machine_num
                break;;

            [Nn]* ) 
                echo -e "\nUsing default Machine-ID for saving results\n"
                machine_num="1"
                break;;

            * ) 
                echo -e "\nInvalid value, please answer (y/n)\n";;

        esac

    done

    # Getting the number of test runs required
    while true; do

        # Prompt the user to input an integer
        read -p "Enter the number of test runs required: " user_run_num

        # Check if the input is a valid integer and store value
        if [[ $user_run_num =~ ^[0-9]+$ ]]; then
            number_of_runs=$user_run_num
            echo -e "Number of test runs set to - $number_of_runs\n"
            break
        else
            echo -e "Invalid input. Please enter a valid integer.\n"
        fi
    
    done

}

#-------------------------------------------------------------------------------------------------------------------------------
function setup_test_suite() {
    # Function for setting up the test suite directories and removing old results if needed

    # Outputting current task to terminal
    echo "#########################"
    echo "Configure Test Parameters"
    echo -e "#########################\n"

    # Getting test options from user and setting results path for machine ID
    get_test_options
    set_result_paths

    # Creating unparsed-results directories for machine ID and handling old results if present
    if [ -d "$test_data_dir/up-results" ]; then

        # Check if there is already results present for assigned machine number and offer to replace
        if [ -d "$machine_results_path" ]; then
            handle_machine_id_clash
        else
            mkdir -p "$machine_speed_results"
            mkdir -p "$kem_mem_results" && mkdir -p "$sig_mem_results"
        fi

    else
        mkdir -p "$machine_speed_results"
        mkdir -p "$kem_mem_results" && mkdir -p "$sig_mem_results"
    fi

    # Setting liboqs test/bin dir path
    liboqs_test_path="$liboqs_path/build/tests/"

    # Setting paths to speed test binaries
    kem_speed_bin="$liboqs_test_path/speed_kem"
    sig_speed_bin="$liboqs_test_path/speed_sig"

    # Setting paths to memory test binaries
    kem_mem_bin="$liboqs_test_path/test_kem_mem"
    sig_mem_bin="$liboqs_test_path/test_sig_mem"

    # Ensure liboqs binaries are present and executable
    test_bins=("$kem_speed_bin" "$sig_speed_bin" "$kem_mem_bin" "$sig_mem_bin")

    for test_binary in "${test_bins[@]}"; do

        if [ ! -f "$test_binary" ]; then
            echo -e "\n\n!!! Liboqs test binaries - ($test_binary) not present, please verify build !!!"
            exit 1
        elif [ ! -x "$test_binary" ]; then
            echo -e "\n\n!!! Liboqs test binaries - ($test_binary) not executable, please verify binary permissions !!!"
            exit 1
        fi

    done

    # Setting alg list txt paths
    kem_alg_file="$test_data_dir/alg-lists/kem-algs.txt"
    sig_alg_file="$test_data_dir/alg-lists/sig-algs.txt"

    # Creating algorithm list arrays
    kem_algs=()
    while IFS= read -r line; do
        kem_algs+=("$line")
    done < $kem_alg_file

    sig_algs=()
    while IFS= read -r line; do
        sig_algs+=("$line")
    done < $sig_alg_file

    # Declaring algorithm operations arrays
    op_kem=("Keygen" "Encaps" "Decaps")
    op_sig=("Keygen" "Sign" "Verify")

    # Creating tmp mem dirs for storing valgrind operation files
    mem_tmp_dir="$tmp_dir/mem_test_tmp"
    rm -rf "$mem_tmp_dir/" && mkdir -p "$mem_tmp_dir"

}

#-------------------------------------------------------------------------------------------------------------------------------
function mem_tests() {
    # Function for performing the Liboqs memory benchmarking tests

    # Outputting current task to terminal
    echo -e "***********************"
    echo -e "Performing Memory Tests"
    echo -e "***********************\n"

    # Ensuring liboqs-mem-tmp dir is not present before starting
    if [ -d "$test_scripts_path/tmp/" ]; then
        rm -rf "$test_scripts_path/tmp/"
    fi

    # Performing the memory tests with the specified number of runs
    for run_count in $(seq 1 $number_of_runs); do

        # Outputting current test run
        echo -e "Memory Test Run - $run_count\n\n"
        
        # Outputting starting kem algorithm tests
        echo -e "KEM Memory Tests\n"

        # KEM memory tests
        for kem_alg in "${kem_algs[@]}"; do

            # Testing memory metrics for each operation
            for operation in {0..2}; do

                # Getting operation string and outputting to terminal
                op_kem_str=${op_kem[operation]}
                echo -e "$kem_alg - $op_kem_str Test\n"

                # Running Valgrind profiler and outputting memory metrics
                filename="$kem_mem_results/$kem_alg-$operation-$run_count.txt"
                valgrind --tool=massif --stacks=yes --massif-out-file="$mem_tmp_dir/massif.out" "$kem_mem_bin" "$kem_alg" "$operation"
                ms_print "$mem_tmp_dir/massif.out" > $filename
                rm -f "$mem_tmp_dir/massif.out" && echo -e "\n"
  
            done

            # Clearing the tmp directory before next test
            rm -rf "$test_scripts_path/tmp/"

        done

        # Outputting starting digital signature tests
        echo -e "\nDigital Signature Memory Tests\n"

        # Digital signature memory tests
        for sig_alg in "${sig_algs[@]}"; do

            # Testing memory metrics for each operation
            for operation in {0..2}; do

                # Getting operation string and outputting to terminal
                op_sig_str=${op_sig[operation]}
                echo -e "$sig_alg - $op_sig_str Test\n"

                # Running valgrind and outputting metrics
                filename="$sig_mem_results/$sig_alg-$operation-$run_count.txt"
                valgrind --tool=massif --stacks=yes --massif-out-file="$mem_tmp_dir/massif.out" "$sig_mem_bin" "$sig_alg" "$operation"
                ms_print "$mem_tmp_dir/massif.out" > $filename
                rm -f "$mem_tmp_dir/massif.out" && echo -e "\n"

            done

            # Clearing the tmp directory before the next test
            rm -rf "$test_scripts_path/tmp/"

        done

        # Cleaning up mem tmp dirs
        rm -rf $mem_tmp_dir && rm -rf "$test_scripts_path/tmp"
        mkdir -p "$mem_tmp_dir"

    done

    # Performing final clean up of Liboqs memory test tmp dirs
    rm -rf $mem_tmp_dir
    rm -rf "$test_scripts_path/tmp"

}

#-------------------------------------------------------------------------------------------------------------------------------
function speed_tests() {
    # Function for performing the Liboqs CPU speed benchmarking tests

    # Outputting current task to terminal
    echo "######################"
    echo "Performing Speed Tests"
    echo -e "######################\n"

    # Performing CPU speed testing for the specified number of runs
    for run_num in $(seq 1 $number_of_runs); do 

        # Conducting KEM performance testing
        echo -e "Conducting KEM Speed Test Run Number - $run_num\n"
        "$kem_speed_bin" > "$machine_speed_results/test-kem-speed-$run_num.csv"

        # Conducting Digital Signature performance testing
        echo -e "Conducting Sig Speed Test Run number - $run_num\n"
        "$sig_speed_bin" > "$machine_speed_results/test-sig-speed-$run_num.csv"

    done

}

#-------------------------------------------------------------------------------------------------------------------------------
function main() {
    # Main function for controlling Liboqs performance testing

    # Performing test suite setup 
    setup_test_suite

    # Performing liboqs speed and memory performance tests
    speed_tests
    mem_tests

    # Outputting complete message with results path for user
    echo -e "All performance testing complete, the unparsed results for Machine-ID ($machine_num) can be found in:"
    echo "Results Dir Path - $machine_results_path"

}
main