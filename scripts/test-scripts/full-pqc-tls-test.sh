#!/bin/bash

#Copyright (c) 2023 Callum Turino
#SPDX-License-Identifier: MIT

# Script for controlling the OQS-OpenSSL benchmark testing, it takes in the test parameters and call the relevant test scripts.
# The script will also determine which test machine it is being executed on within the test parameter collection functions. This script will 
# need to be executed on both machines to operate Furthermore, the keys for the test will need to be generated first using the oqsssl-generate-keys.sh
# script and transferred to the client machine before the tests are ran. 

#------------------------------------------------------------------------------
# Declaring directory path variables
root_dir=$(cd "$PWD"/../.. && pwd)
libs_dir="$root_dir/lib"
tmp_dir="$root_dir/tmp"
test_data_dir="$root_dir/test-data"
test_scripts_path="$root_dir/scripts/test-scripts"

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

# Declaring option variables
machine_type=""
MACHINE_NUM=""


#------------------------------------------------------------------------------
function set_paths() {

    # Setting results path based on assigned machine number for results
    export MACHINE_RESULTS_PATH="$test_data_dir/up-results/oqs-openssl/machine-$MACHINE_NUM"
    export MACHINE_HANDSHAKE_RESULTS="$MACHINE_RESULTS_PATH/handshake-results"
    export MACHINE_SPEED_RESULTS="$MACHINE_RESULTS_PATH/speed-results"

    # Setting specific test types results paths
    export PQC_HANDSHAKE="$MACHINE_HANDSHAKE_RESULTS/pqc"
    export CLASSIC_HANDSHAKE="$MACHINE_HANDSHAKE_RESULTS/classic"
    export HYBRID_HANDSHAKE="$MACHINE_HANDSHAKE_RESULTS/hybrid"

    export PQC_SPEED="$MACHINE_SPEED_RESULTS/pqc"
    export CLASSIC_SPEED="$MACHINE_SPEED_RESULTS/classic"
    export HYBRID_SPEED="$MACHINE_SPEED_RESULTS/hybrid"

    # Decalring result paths array
    result_dir_paths=("$PQC_HANDSHAKE" "$CLASSIC_HANDSHAKE" "$HYBRID_HANDSHAKE" "$PQC_SPEED" "$CLASSIC_SPEED" "$HYBRID_SPEED")

}

#------------------------------------------------------------------------------
function clean_environment() {

    # Unsetting root results paths
    unset MACHINE_RESULTS_PATH
    unset MACHINE_HANDSHAKE_RESULTS
    unset MACHINE_SPEED_RESULTS

    # Unsetting test params vars
    unset MACHINE_NUM
    unset MACHINE_TYPE
    unset NUM_RUN
    unset TIME_NUM
    unset SPEED_NUM
    unset CLIENT_IP
    unset SERVER_IP
    unset LD_LIBRARY_PATH

    # Unsetting result types paths 
    for var in "${result_dir_paths[@]}"; do
        unset $var
    done

    # Unsetting IP vars depening on machine type
    if [ $machine_type == "Server" ]; then
        unset CLIENT_IP
    else
        unset SERVER_IP
    fi

}

#------------------------------------------------------------------------------
function get_machine_num() {

    while true; do
        read -p "What machine number would you like to assign to these results? - " response
        case $response in

            # Asking the user to enter a number
            ''|*[!0-9]*) echo -e "Invalid value, please enter a number\n"; 
            continue;;

            # If a number is entered by the user it is stored for later use
            * ) MACHINE_NUM="$response"; echo -e "\nMachine-ID set to $response\n";
            break;;
        esac
    done
    
}

#------------------------------------------------------------------------------
function handle_machine_id_clash() {

    # Get user choice for handling clash
    while true; do

        # Outputting options
        echo -e "There are already results stored for Machine-ID ($MACHINE_NUM), would you like to:"
        echo -e "1 - Replace old results and keep same Machine-ID"
        echo -e "2 - Assign a different machine ID"
        read -p "Enter Option: " user_response

        case $user_response in

            1)
                echo -e "\nReplacing old results\n"
                rm -rf $MACHINE_RESULTS_PATH

                for result_dir in "${result_dir_paths[@]}"; do
                    mkdir -p "$result_dir"
                done

                break;;

            2)

                # Getting new machine ID to be assigned to results
                echo -e "Assigning new Machine-ID for test results"
                get_machine_num

                # Setting results path based on assigned machine number for results
                set_paths

                # Ensuring the new ID does not have results stored
                if [ ! -d "$MACHINE_RESULTS_PATH" ]; then
                    echo -e "No previous results present for Machine-ID ($MACHINE_NUM), continuing test setup"
                    break
                else
                    echo "There are previous results detected for new Machine-ID value, please select different value or replace old results"
                fi
                ;;
        
        esac

    done

}

#------------------------------------------------------------------------------
function configure_results_dir() {

    set_paths

    # Creating unparsed results directorys for machine ID and handling old results if present
    if [ -d "$test_data_dir/up-results" ]; then
    
        # Check if there is already results present for assigned machine number and offer to replace
        if [ -d "$MACHINE_RESULTS_PATH" ]; then
            handle_machine_id_clash
        else
            
            for result_dir in "${result_dir_paths[@]}"; do
                mkdir -p "$result_dir"
            done
        fi

    else
        for result_dir in "${result_dir_paths[@]}"; do
            mkdir -p "$result_dir"
        done
    fi
}

#------------------------------------------------------------------------------
function get_test_comparison_choice() {

    # Getting input from user to determine if machine will be compared
    while true; do

        echo "Please select on of the following test comparison options"
        echo "1-This test will not be used in result-parsing with other machines"
        echo "2-This machine will be used in result-parsing with other machine results"
        read -p "Enter your choice (1-2): " usr_test_option

        # Determining action from user input
        case $usr_test_option in
            1)
                # Setting default machine-ID
                echo "Test will not be parsed with other machine data"
                export MACHINE_NUM="1"
                configure_results_dir
                break
                ;;      
            2)

                # Setting user specified Machine-ID after checking results storage
                echo "Test will will be parsed with other machine data"
                configure_results_dir
                export MACHINE_NUM="$MACHINE_NUM"
                break
                ;;
            *)
                echo "Invalid option, please select valid option value (1-2)"
                ;;
        esac

    done

}

#------------------------------------------------------------------------------
function configure_test_options {
    # Function for getting all the needed test parameter options from the user needed for the testing

    # Outputting option parameter title

    echo -e "\n#########################"
    echo "Configure Test Parameters"
    echo -e "#########################\n"

    # Getting input from user to determine test machine
    while true; do

        #Asking the user which test machine this is
        echo "Please select on of the following test machine options to configure machine type:"
        echo "1-This machine will be the server"
        echo "2-This machine will be the client"
        echo "3-Exit"
        read -p "Enter your choice (1-3): " usr_mach_option

        # Determining action from user input
        case $usr_mach_option in
            1)
                echo -e "\nServer machine type selected\n"
                machine_type="Server"
                break
                ;;    
            2)
                echo -e "\nClient machine type selected\n"
                machine_type="Client"
                break
                ;;
            3)
                echo "Exiting test suite"
                exit 1
                break
                ;;
            *)
                echo "Invalid option, please select valid option value (1-3)"
                ;;
        esac

    done

    # Getting input from user to determine the number of runs
    while true; do

        # Prompt the user to input an integer
        read -p "Enter the number of test runs required: " user_run_num

        # Check if the input is a valid integer
        if [[ $user_run_num =~ ^[0-9]+$ ]]; then

            # Store the user input in env
            export NUM_RUN="$user_run_num"
            break

        else
            echo -e "Invalid input. Please enter a valid integer.\n"
        fi
    
    done

    # If test machine is client, getting TLS handshake and speed test length
    if [ $machine_type == "Client" ]; then

        # Get machine-ID for results if comparing to other results
        get_test_comparison_choice

        # Getting input from user to determine the TLS test length
        while true; do

            # Prompt the user to input an integer
            read -p "Enter the desired length for each TLS Handshake test in seconds: " user_time_num

            # Check if the input is a valid integer
            if [[ $user_time_num =~ ^[0-9]+$ ]]; then

                # Store the user input
                export TIME_NUM="$user_time_num"
                break
            
            else
                echo -e "Invalid input. Please enter a valid integer.\n"
            fi
        
        done

        # Getting input from user to determine the tls speed test length
        while true; do

            # Prompt the user to input an integer
            read -p "Enter the test length in seconds for the TLS speed tests: " user_speed_num

            # Check if the input is a valid integer
            if [[ $user_speed_num =~ ^[0-9]+$ ]]; then

                # Store the user input
                export SPEED_NUM="$user_speed_num"
                break

            else
                echo -e "Invalid input. Please enter a valid integer.\n"
            fi
        
        done

    fi

}

#------------------------------------------------------------------------------
function check_transferred_keys() {
    # Function for ensuring the user has transferred the certs and keys have been
    # generated and transferred to the client machine before starting tests

    # Checking with user if keys have been transferred
    while true; do

        read -p "Have you generated and transferred the testing keys to the client machine [y/n] - " key_response
        case $key_response in

            [Yy]* )
                break;;

            [Nn]* ) 
                echo -e "\nPlease generate the certs and keys needed for testing using oqsssl-generate-keys.sh and transfer to client machine before testing"
                echo -e "\nExiting test..."
                sleep 2
                exit 0
                ;;
        esac
    
    done

}

#------------------------------------------------------------------------------
function run_tests() {
    # Function that will call the relevant benchmarking scripts
    
    # Ask the user for the client ip
    ipv4_regex_check="^([0-9]{1,3}\.){3}[0-9]{1,3}$"

    while true; do

        # Getting user input
        echo -e "\nConfigure IP Parameters:"
        read -p "Please enter the $machine_type machine's IP address: " usr_ip_input

        # Formatting user ip input by removing trailing spaces
        ip_address=$(echo $usr_ip_input | tr -d ' ')

        if [[ $ip_address =~ $ipv4_regex_check ]]; then
            echo "Other test machine set to - $ip_address"
            machine_ip=$ip_address
            break
        else
            echo "Invalid IP format, please try again"
        fi
    
    done

    # Outputting reminder to move keys before starting test (will automate in future)
    echo -e "\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo -e "Please ensure that you have generated and transferred keys before starting test"
    echo -e "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n"

    # Calling key transfer check
    check_transferred_keys

    # clearing output to tidy test output
    clear

    # Outputting test type message
    echo -e "\n####################################"
    echo "Performing TLS Handshake Tests"
    echo -e "####################################\n"

    # Running handshake test script based on machine type
    if [ $machine_type == "Server" ]; then

        # Storing client IP in environment var
        export CLIENT_IP="$machine_ip"

        # Running test script
        $test_scripts_path/oqsssl-test-server.sh 
        #>> "$root_dir/server-test-output.txt" - uncomment to save output for debugging

    else

        # Storing server IP in environment var
        export SERVER_IP="$machine_ip"

        # Running handshake test script
        $test_scripts_path/oqsssl-test-client.sh 
        #>> "$root_dir/client-test-output.txt" - uncomment to save output for debugging

        # # Running ssl-speed tests
        # echo -e "\n##########################"
        # echo "Performing TLS Speed Tests"
        # echo -e "##########################\n"

        # $test_scripts_path/oqsssl-test-speed.sh
    
    fi

}

#------------------------------------------------------------------------------
function main() {
    # Main function for controlling OQS-OpenSSL testing

    # Greeting message
    echo -e "PQC OQS-Provider Test Suite (OpenSSL_3.2.1)"

    # Getting test options
    configure_test_options

    # Running tests
    run_tests

    # Cleaning environment
    clean_environment
}
main