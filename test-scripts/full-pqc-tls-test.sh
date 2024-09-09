#!/bin/bash

#Copyright (c) 2023 Callum Turino
#SPDX-License-Identifier: MIT

# Script for controlling the OQS-OpenSSL benchmark testing, it takes in the test parameters and call the relevant test scripts.
# The script will also determine which test machine it is being executed on within the test parameter collection functions. This script will 
# need to be executed on both machines to operate Furthermore, the keys for the test will need to be generated first using the oqsssl-generate-keys.sh
# script and transferred to the client machine before the tests are ran. 

#------------------------------------------------------------------------------
# Declaring directory path variables
current_dir=$(pwd)
root_dir=$(dirname "$current_dir")
device_name=$(hostname)
test_scripts_dir="$root_dir/test-scripts"
up_results_dir="$root_dir/up-results"

# Declaring option variables
machine_type=""
test_compare_flag=""
machine_num="1"

#------------------------------------------------------------------------------
function get_machine_num() {
    # Function for setting the machine number associated withe the outputted results

    # Getting the machine number in
    while true; do

        read -p "What machine number would you like to assign to these results? - " number_response

        case $number_response in

            # Asking the user to enter a number
            ''|*[!0-9]*) echo -e "\nPlease enter a number\n"; 
            continue;;

            # If a number is entered by the user it is stored for later use
            * ) machine_num="$number_response"; echo -e "\nMachine number set to $number_response\n";
            break;;
        esac
    
    done

}

#------------------------------------------------------------------------------
function get_test_options {
    # Function for getting all the needed test parameter options from the user needed for the testing

    # Outputting option parameter title
    echo "Machine Type Selection:"
    echo -e "**************************\n"

    # Getting input from user to determine test machine
    while true; do

        #Asking the user which test machine this is
        echo "Please select on of the following test machine options"
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

    # Outputting option parameter title
    echo "Test Comparison Selection:"
    echo -e "**************************\n"

    # Getting input from user to determine if machine will be compared
    while true; do

        echo "Please select on of the following test comparison options"
        echo "1-This test will not be used in result-parsing with other machines"
        echo "2-This machine will be used in result-parsing with other machine results"
        read -p "Enter your choice (1-2): " usr_test_option

        # Determining action from user input
        case $usr_test_option in
            1)
                echo "Test will not be parsed with other machine data"
                test_compare_flag="0"
                break
                ;;      
            2)
                echo "Test will will be parsed with other machine data"
                test_compare_flag="1"
                get_machine_num            
                break
                ;;
            *)
                echo "Invalid option, please select valid option value (1-2)"
                ;;
        esac

    done
    
    # Outputting option parameter title
    echo -e "\nNumber of Runs for Tests Selection"

    # Getting input from user to determine the number of runs
    while true; do

        # Prompt the user to input an integer
        read -p "Enter the number of test runs required: " user_run_num

        # Check if the input is a valid integer
        if [[ $user_run_num =~ ^[0-9]+$ ]]; then

            # Store the user input
            echo $user_run_num > "$root_dir/tmp/tls_number_of_runs.txt"
            break

        else
            echo -e "Invalid input. Please enter a valid integer.\n"
        fi
    
    done

    # If test machine is client, getting TLS handshake and speed test length
    if [ $machine_type == "Client" ]; then

        # Outputting option parameter title
        echo -e "\nSpecification of TLS Test Length"

        # Getting input from user to determine the TLS test length
        while true; do

            # Prompt the user to input an integer
            read -p "Enter the desired length for each TLS Handshake test in seconds: " user_time_num

            # Check if the input is a valid integer
            if [[ $user_time_num =~ ^[0-9]+$ ]]; then

                # Store the user input
                echo $user_time_num > "$root_dir/tmp/tls_test_length.txt"
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
                echo $user_speed_num > "$root_dir/tmp/tls_speed_time.txt"
                break

            else
                echo -e "Invalid input. Please enter a valid integer.\n"
            fi
        
        done

    fi

    # Getting input from user to determine the tls speed test length
    while true; do

        # Prompt the user to input an integer
        read -p "Enter the test length in seconds for the TLS speed tests: " user_speed_num

        # Check if the input is a valid integer
        if [[ $user_speed_num =~ ^[0-9]+$ ]]; then

            # Store the user input
            echo $user_speed_num > "$root_dir/tmp/tls_speed_time.txt"
            break

        else
            echo -e "Invalid input. Please enter a valid integer.\n"
        fi
    
    done

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
                sleep 5
                exit 0
                ;;
        esac
    
    done

}

#------------------------------------------------------------------------------
function run_tests() {
    # Function that will call the relevant benchmarking scripts

    # Checking for needed openssl results dir for test script checks
    if [ ! -d "$up_results_dir/openssl/" ]; then
        mkdir -p "$up_results_dir/openssl"
    fi

    # Removing old completed results
    for old_results_dir in "$up_results_dir/openssl/machine-"*; do

        # Removing current old results dir
        if [ -d "$old_results_dir" ]; then
            rm -rf "$old_results_dir"
        fi
    done
    
    # Ask the user for the client ip
    ipv4_regex_check="^([0-9]{1,3}\.){3}[0-9]{1,3}$"

    while true; do

        # Getting user input
        echo -e "\nGetting Other Test Machine's IP"
        read -p "Please enter the other test machine's IP address:- " usr_ip_input

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

    # Running handshake test script based on machine type
    if [ $machine_type == "Server" ]; then

        # Server test machine

        # Saving client machine's ip
        echo $ip_address > "$root_dir/tmp/client-ip.txt"

        # Outputting reminder to move keys before starting test (will automate in future)
        echo -e "\n*****************************************************************************\n"
        echo -e "Please ensure that you have generated and transferred keys before starting test"
        echo -e "*****************************************************************************\n"

        # Calling key transfer check
        check_transferred_keys

        # Running test script
        $test_scripts_dir/oqsssl-test-server.sh 
        #>> "$root_dir/server-test-output.txt" - uncomment to save output for debugging

    else
        # Client test machine

        # Saving servers machine's ip
        echo $machine_ip > "$root_dir/tmp/server-ip.txt"

        # Outputting reminder to move keys before starting test (will automate in future)
        echo -e "Please ensure that you have generated and transferred keys before starting test"
        echo -e "Please ensure server machine has started before activating client\n"

        # Running test script
        $test_scripts_dir/oqsssl-test-client.sh 
        #>> "$root_dir/client-test-output.txt" - uncomment to save output for debugging
    
    fi

    # Running alg ssl-speed tests if machine is client
    if [ $machine_type == "Client" ]; then
        clear
        echo -e "\nRunning Alg Speed Tests\n"
        $test_scripts_dir/oqsssl-test-speed.sh
    fi

}

#------------------------------------------------------------------------------
function main() {
    # Main function for controlling OQS-OpenSSL testing

    # Greeting message
    echo -e "OQS-OpenSSL (1.1.1u) Test Suite"

    # Getting test options
    get_test_options

    # Creating openssl up-results and removing old if needed
    if [ -d "$root_dir/up-results/openssl" ]; then
        rm -rf "$root_dir/up-results/openssl"
    fi
    mkdir -p "$root_dir/up-results/openssl" 

    # Running tests
    run_tests

    # Moving results if client machine
    if [ $machine_type == "Client" ]; then
        mkdir -p $up_results_dir/openssl/machine-$machine_num
        mv $up_results_dir/openssl/pqc-tests "$up_results_dir/openssl/machine-$machine_num/pqc-tests"
        mv $up_results_dir/openssl/classic-tests "$up_results_dir/openssl/machine-$machine_num/classic-tests"
        mv $up_results_dir/openssl/speed-tests "$up_results_dir/openssl/machine-$machine_num/speed-tests"
    fi

}
main