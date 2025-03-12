#!/bin/bash

# Copyright (c) 2025 Callum Turino
# SPDX-License-Identifier: MIT

# Script for controlling the OQS-Provider benchmark testing, it takes in the test parameters and calls the relevant test scripts.
# The script will also determine which test machine it is being executed on within the test parameter collection functions. 
# This script will  need to be executed on both machines to operate. Furthermore, the keys for the test will need to be generated first using 
# the oqsprovider-generate-keys.sh script and transferred to the client machine before the tests are ran. 
# If executing both server and client on the same machine, this is not needed as the client can access the keys directly.

#-------------------------------------------------------------------------------------------------------------------------------
function get_user_yes_no() {
    # Helper function for getting a yes or no response from the user for a given question regarding the setup process

    local user_prompt="$1"

    # Get the user input for the yes or no question
    while true; do
        read -p "$user_prompt (y/n): " user_input

        case $user_input in

            [Yy]* )
                user_y_n_response=1
                return 0
                ;;

            [Nn]* )
                user_y_n_response=0
                return 1
                ;;

            * )
                echo -e "Please answer y or n\n"
                ;;

        esac

    done

}

#-------------------------------------------------------------------------------------------------------------------------------
function is_valid_port() {
    # Helper function called by parse_script_flags to check if the custom port passed to the script when called is a valid TCP port number

    # Store passed value and check if it is a valid port number
    local port="$1"
    if [[ "$port" =~ ^[0-9]+$ ]] && (( port >= 1024 && port <= 65535 )); then
        return 0
    else
        return 1
    fi

}

#-------------------------------------------------------------------------------------------------------------------------------
function parse_script_flags {
    # Function for parsing the flags passed to the script when called

    # Check if custom control port flags have been passed to the script
    while [[ $# -gt 0 ]]; do

        case "$1" in

            --server-control-port=*)
                # Store the custom server control port number
                server_control_port="${1#*=}"

                # Check if the port number is valid
                if ! is_valid_port "$server_control_port"; then
                    echo "[ERROR] - Invalid server control port number: $server_control_port"
                    exit 1
                fi
                shift
                ;;

            --client-control-port=*)

                # Store the custom client control port number
                client_control_port="${1#*=}"

                # Check if the port number is valid
                if ! is_valid_port "$client_control_port"; then
                    echo "[ERROR] - Invalid client control port number: $client_control_port"
                    exit 1
                fi
                shift
                ;;

            --s-server-port=*)

                # Store the custom s_server port number
                s_server_port="${1#*=}"

                # Check if the port number is valid
                if ! is_valid_port "$s_server_port"; then
                    echo "[ERROR] - Invalid s_server port number: $s_server_port"
                    exit 1
                fi
                shift
                ;;

            --control-sleep-time=*)

                # Check to see if the disable control sleep flag has been set
                if [ "$disable_control_sleep" == "True" ]; then
                    echo "[ERROR] - Cannot use the --control-sleep-time flag when the --disable-control-sleep flag has been set"
                    exit 1
                fi

                # Store the custom control sleep time and set the custom control time flag
                control_sleep_time="${1#*=}"
                custom_control_time_flag="True"

                # Check if the sleep timer is valid integer or float
                if [[ ! $control_sleep_time =~ ^[0-9]+([.][0-9]+)?$ ]]; then
                    echo "[ERROR] - Invalid control sleep time: $control_sleep_time"
                    exit 1
                fi
                shift
                ;;

            --disable-control-sleep)

                # Check if the custom sleep time flag has been
                if [ "$custom_control_time_flag" == "True" ]; then
                    echo "[ERROR] - Cannot use the --disable-control-sleep flag when the --control-sleep-time flag has been set"
                    exit 1
                fi

                # Set the disable control sleep flag and shift
                disable_control_sleep="True"
                shift
                ;;


            *)
                echo "[ERROR] - Unknown option: $1"
                echo "Valid options are:"
                echo "  --server-control-port=<PORT>       Set the server control port             (1024-65535)"
                echo "  --client-control-port=<PORT>       Set the client control port             (1024-65535)"
                echo "  --s-server-port=<PORT>             Set the OpenSSL S_Server port           (1024-65535)"
                echo "  --control-sleep-time=<TIME>        Set the control sleep time in seconds   (integer or float)"
                echo "  --disable-control-sleep            Disable the control signal sleep time"
                exit 1
                ;;

        esac

    done

    # Ensure that no custom ports are the same
    if [ "$server_control_port" == "$client_control_port" ] || [ "$server_control_port" == "$s_server_port" ] || [ "$client_control_port" == "$s_server_port" ]; then
        echo -e "[ERROR] - Custom TCP ports cannot be the same"
        exit 1
    fi

    # If the custom control sleep time flag has been set, perform additional checks
    if [ "$custom_control_time_flag" == "True" ]; then

        # Check if the set sleep time value falls into given special cases
        if (( $(echo "$control_sleep_time > 0 && $control_sleep_time < 0.25" | bc -l) )); then

            # Output warning to the user
            echo "[WARNING] - Control sleep time is below the lowest tested value of 0.25 seconds"
            echo "In most instances this should be fine, but some environments have shown testing to fail using lower values"

            # Ask the user if they wish to continue with the lower value
            get_user_yes_no "Do you wish to continue with the sleep timer set to $control_sleep_time seconds?"

            # Check the user response
            if [ $user_y_n_response -eq 0 ]; then
                echo -e "\nExiting script..."
                exit 1
            fi

        elif (( $(echo "$control_sleep_time == 0" | bc -l) )); then

            # Output the situation to the user and get their response
            echo "[NOTICE] - You have set the control sleep time to 0 seconds"
            get_user_yes_no "Do you wish to disable the control signal sleep statement?"

            # Check the user response
            if [ $user_y_n_response -eq 1 ]; then
                disable_control_sleep="True"
            else
                echo -e "\nExiting script..."
                exit 1
            fi

        fi
    
    fi

}

#-------------------------------------------------------------------------------------------------------------------------------
function is_port_in_use() {
    # Helper function to determine if a given port is in use. The function will attempt to use various system tools to check if the port is in use.
    # Once the available system tool has been determine, the function checks if a process is using the port, it then stores the process name 
    # in `port_process` and the process ID in `port_pid`.

    # Store the port number and initialize the process name and PID
    local port="$1"
    port_process=""
    port_pid=""
    system_net_tool=""

    # Attempt to check if the port is in use and, if so, store the process name and PID
    if command -v ss &>/dev/null; then

        # Set the system network tool to ss
        system_net_tool="ss"

        # Grab the process ID and process name when supplying the port number
        port_pid=$(ss -tulnp | awk -v port=":$port" '$0 ~ port {gsub(".*pid=","",$NF); gsub(",.*","",$NF); print $NF}')
        port_process=$(ss -tulnp | awk -v port=":$port" '$0 ~ port {for (i=1; i<=NF; i++) if ($i ~ /users:\(\("/) {print $i; exit}}' | sed -E 's/users:\(\("//;s/",pid=.*//')

        # Determine if the port is in use based on if a process ID is found
        if [[ -n "$port_pid" ]]; then
            return 0
        fi

    elif command -v netstat &>/dev/null; then

        # Set the system network tool to netstat
        system_net_tool="netstat"

        # Grab the process ID and process name when supplying the port number
        port_pid=$(netstat -tulnp 2>/dev/null | grep ":$port" | awk '{print $7}' | cut -d'/' -f1)
        port_process=$(netstat -tulnp 2>/dev/null | grep ":$port" | awk '{print $7}' | cut -d'/' -f2)

        # Determine if the port is in use based on if a process ID is found
        if [[ -n "$port_pid" ]]; then
            return 0
        fi

    elif command -v lsof &>/dev/null; then

        # Set the system network tool to lsof
        system_net_tool="lsof"

        # Grab the process ID and process name when supplying the port number
        port_pid=$(lsof -Pi :"$port" -sTCP:LISTEN -t 2>/dev/null)

        # Determine if the port is in use based on if a process ID is found
        if [[ -n "$port_pid" ]]; then
            port_process=$(ps -p "$port_pid" -o comm= 2>/dev/null | awk '{$1=$1};1')
            return 0
        fi

    else

        # Output warning that no tool was found to check port usage
        echo -e "[WARNING] - No tool found to check port usage (lsof, ss, netstat)\n"

        # Ask the user if they wish to proceed without checking
        while true; do

            read -p "Do you wish to continue without checking if the control ports are already in use? [y/n] - " user_response

            case $user_response in

                [Yy]* )
                    skip_port_check="True"
                    return 1
                    ;;

                [Nn]* )
                    echo -e "\nExiting script..."
                    exit 1
                    ;;

                * )
                    echo -e "Please enter a valid response [y/n]\n"
                    ;;

            esac

        done

    fi

    # Return that no process is using the passed port
    return 1

}

#-------------------------------------------------------------------------------------------------------------------------------
function setup_base_env() {
    # Function for setting up the basic global variables for the test suite. This includes setting the root directory
    # and the global library paths for the test suite. The function establishes the root path by determining the path of the script and
    # using this, determines the root directory of the project.

    # Outputting greeting message to the terminal
    echo -e "PQC OQS-Provider Test Suite (OpenSSL_3.4.1)\n"

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
    openssl_path="$libs_dir/openssl_3.4"

    # Exporting OpenSSL library path
    if [[ -d "$openssl_path/lib64" ]]; then
        openssl_lib_path="$openssl_path/lib64"
    else
        openssl_lib_path="$openssl_path/lib"
    fi

    export LD_LIBRARY_PATH="$openssl_lib_path:$LD_LIBRARY_PATH"

    # Declaring option variables
    machine_type=""
    MACHINE_NUM="1"

    # Exporting the TCP port variables
    export SERVER_CONTROL_PORT="$server_control_port"
    export CLIENT_CONTROL_PORT="$client_control_port"
    export S_SERVER_PORT="$s_server_port"

    # Determine what control signal parameters to export
    if [ "$disable_control_sleep" == "False" ] && [ "$custom_control_time_flag" == "False" ]; then
        export CONTROL_SLEEP_TIME="0.25"

    elif [ "$disable_control_sleep" == "False" ] && [ "$custom_control_time_flag" == "True" ]; then
        export CONTROL_SLEEP_TIME="$control_sleep_time"
    
    elif [ "$disable_control_sleep" == "True" ]; then
        export DISABLE_CONTROL_SLEEP="True"

    fi

    # Define the flag and arrays used for the port checking
    skip_port_check="False"
    ports_to_check=("$server_control_port" "$client_control_port" "$s_server_port")
    port_names=("Server control port" "Client control port" "OpenSSL S_Server port")

    # Ensure that control ports are not in use by other processes in the system
    for custom_port_index in "${!ports_to_check[@]}"; do

        # Check if the port is in use in the system if the user has not chosen to skip the check due to missing tools
        if [ "$skip_port_check" != "True" ] && is_port_in_use "${ports_to_check[$custom_port_index]}"; then

            # Extract where the process pid is being ran from for the port being checked
            process_cmdline=$(readlink -f /proc/$port_pid/cwd)

            # Check if the conflicting process is from this test suite
            if echo "$process_cmdline" | grep -q "$root_dir"; then

                # Determine if the process is from this testing suite
                if [ "$port_process" == "nc" ] && [ "$custom_port_index" -ne 2 ]; then
                    continue

                elif [ "$custom_port_index" -eq 2 ] && [ "$port_process" == "openssl" ]; then
                    echo "[WARNING] - ${port_names[$custom_port_index]} is active from a previous test, killing the process"
                    kill -9 "$port_pid"

                else
                    echo "[ERROR] - A service in the project is using the port: ${ports_to_check[$custom_port_index]}, this should not be the case"
                    echo "Please manually stop the service and try again"
                    exit 1

                fi

            else

                # Output error message and exit the script
                echo -e "[ERROR] - ${port_names[$custom_port_index]} is already in use, Port: ${ports_to_check[$custom_port_index]}"
                echo "$port_process is using the port"
                exit 1

            fi

        fi

    done

}

#-------------------------------------------------------------------------------------------------------------------------------
function set_tls_paths() {
    # Function for setting the results paths based on the machine number assigned 
    # to the test and exporting the paths to the environment

    # Setting results path based on assigned machine number for results
    export MACHINE_RESULTS_PATH="$test_data_dir/up-results/oqs-provider/machine-$MACHINE_NUM"
    export MACHINE_HANDSHAKE_RESULTS="$MACHINE_RESULTS_PATH/handshake-results"
    export MACHINE_SPEED_RESULTS="$MACHINE_RESULTS_PATH/speed-results"

    # Setting specific test types results paths
    export PQC_HANDSHAKE="$MACHINE_HANDSHAKE_RESULTS/pqc"
    export CLASSIC_HANDSHAKE="$MACHINE_HANDSHAKE_RESULTS/classic"
    export HYBRID_HANDSHAKE="$MACHINE_HANDSHAKE_RESULTS/hybrid"
    export PQC_SPEED="$MACHINE_SPEED_RESULTS/pqc"
    export HYBRID_SPEED="$MACHINE_SPEED_RESULTS/hybrid"

    # Declaring result paths array
    result_dir_paths=("$PQC_HANDSHAKE" "$CLASSIC_HANDSHAKE" "$HYBRID_HANDSHAKE" "$PQC_SPEED" "$HYBRID_SPEED")

}

#-------------------------------------------------------------------------------------------------------------------------------
function clean_environment() {
    # Function for cleaning the environment after the testing has been completed

    # Clearing root results paths
    unset MACHINE_RESULTS_PATH
    unset MACHINE_HANDSHAKE_RESULTS
    unset MACHINE_SPEED_RESULTS

    # Clearing test params variables
    unset MACHINE_NUM
    unset MACHINE_TYPE
    unset NUM_RUN
    unset TIME_NUM
    unset SPEED_NUM
    unset CLIENT_IP
    unset SERVER_IP
    unset LD_LIBRARY_PATH
    unset SERVER_CONTROL_PORT
    unset CLIENT_CONTROL_PORT
    unset S_SERVER_PORT
    unset CONTROL_SLEEP_TIME

    # Clearing DISABLE_CONTROL_SLEEP variable if set
    if [ -z $DISABLE_CONTROL_SLEEP ]; then
        unset DISABLE_CONTROL_SLEEP
    fi

    # Clearing result types paths 
    for var in "${result_dir_paths[@]}"; do
        unset $var
    done

    # Clearing IP variables depending on machine type
    if [ $machine_type == "Server" ]; then
        unset CLIENT_IP
    else
        unset SERVER_IP
    fi

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
            * ) MACHINE_NUM="$response"; echo -e "\nMachine-ID set to $response\n";
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
        echo -e "There are already results stored for Machine-ID ($MACHINE_NUM), would you like to:"
        echo -e "1 - Replace old results and keep same Machine-ID"
        echo -e "2 - Assign a different machine ID"
        read -p "Enter Option: " user_response

        case $user_response in

            1)
                # Removing old results and creating new directories
                echo -e "\nReplacing old results\n"
                rm -rf $MACHINE_RESULTS_PATH

                for result_dir in "${result_dir_paths[@]}"; do
                    mkdir -p "$result_dir"
                done

                break
                ;;

            2)
                # Getting new machine ID to be assigned to results
                echo -e "Assigning new Machine-ID for test results"
                get_machine_num

                # Setting results path based on assigned machine number for results
                set_tls_paths

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

#-------------------------------------------------------------------------------------------------------------------------------
function configure_results_dir() {
    # Function for configuring the results directories for the test results

    # Setting results paths based on machine ID
    set_tls_paths

    # Creating unparsed-results directories for machine ID and handling old results if present
    if [ -d "$test_data_dir/up-results" ]; then
    
        # Check if there is already results present for assigned machine number and offer to replace
        if [ -d "$MACHINE_RESULTS_PATH" ]; then
            handle_machine_id_clash
        
        else

            # Creating directories for new machine ID
            for result_dir in "${result_dir_paths[@]}"; do
                mkdir -p "$result_dir"
            done

        fi

    else

        # Creating new results directories
        for result_dir in "${result_dir_paths[@]}"; do
            mkdir -p "$result_dir"
        done

    fi

}

#-------------------------------------------------------------------------------------------------------------------------------
function get_test_comparison_choice() {
    # Function for getting the user choice on whether the test results will be compared to other machine results

    # Getting input from user to determine if machine will be compared
    while true; do

        # Outputting the test comparison options to the user and reading in the user response
        echo -e "\nPlease select on of the following test comparison options"
        echo "1-This test will not be used in result-parsing with other machines"
        echo "2-This machine will be used in result-parsing with other machine results"
        read -p "Enter your choice (1-2): " usr_test_option

        # Determining action from user input
        case $usr_test_option in

            1)
                # Setting default machine-ID
                echo -e "\nTest will not be parsed with other machine data\n"
                export MACHINE_NUM="1"
                configure_results_dir
                break
                ;;

            2)
                # Setting user specified Machine-ID after checking results storage
                echo -e "\nTest will will be parsed with other machine data\n"
                get_machine_num
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

#-------------------------------------------------------------------------------------------------------------------------------
function configure_test_options {
    # Function for getting all the needed test parameter options from the user needed for the testing

    # Outputting option parameter title

    echo -e "#########################"
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
                ip_request_string="Client"
                break
                ;;    
            2)
                echo -e "\nClient machine type selected\n"
                machine_type="Client"
                ip_request_string="Server"
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

            # Store the user input in the environment variable
            export NUM_RUN="$user_run_num"
            break

        else
            echo -e "Invalid input. Please enter a valid integer.\n"
        fi
    
    done

    # If test machine is client, getting TLS handshake and speed test lengths from user
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

        # Getting input from user to determine the TLS speed test length
        while true; do

            # Prompt the user to input an integer for the speed test length
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

#-------------------------------------------------------------------------------------------------------------------------------
function check_transferred_keys() {
    # Function for checking with the user has generated and transferred the certs and keys
    # to the client machine before starting tests

    # Checking with the user if keys have been transferred
    while true; do

        read -p "Have you generated and transferred the testing keys to the client machine [y/n] - " key_response
        case $key_response in

            [Yy]* )
                break;;

            [Nn]* ) 
                echo -e "\nPlease generate the certs and keys needed for testing using oqsprovider-generate-keys.sh and transfer to client machine before testing"
                echo -e "\nExiting test..."
                sleep 2
                exit 0
                ;;
            
            * )
                echo "Please enter a valid response [y/n]"
                ;;

        esac
    
    done

}

#-------------------------------------------------------------------------------------------------------------------------------
function run_tests() {
    # Function that will call the relevant benchmarking utility scripts for the TLS handshake and speed tests
   
    # Setting regex variable for checking IP address format entered by user
    ipv4_regex_check="^((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])$"

    # Getting the IP address of the other machine from the user
    while true; do

        # Getting user input
        echo -e "\nConfigure IP Parameters:"
        read -p "Please enter the $ip_request_string machine's IP address: " usr_ip_input

        # Formatting user ip input by removing trailing spaces
        ip_address=$(echo $usr_ip_input | tr -d ' ')

        # Checking if the IP address entered is in the correct format
        if [[ $ip_address =~ $ipv4_regex_check ]]; then

            # Ensure that the IP address is not set to 0.0.0.0 or 255.255.255.255 before continuing
            if [[ "$ip_address" == "0.0.0.0" || "$ip_address" == "255.255.255.255" ]]; then
                echo "Invalid IP address: $ip_address. Please enter a valid IP address."
            else
                echo "Other test machine set to - $ip_address"
                machine_ip=$ip_address
                break
            fi

        else
            echo "Invalid IP format, please try again"

        fi
    
    done

    # Outputting reminder to move keys before starting test (will automate in future)
    echo -e "\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo -e "Please ensure that you have generated and transferred keys before starting test"
    echo -e "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n"

    # Calling key transfer check and clearing output to tidy terminal output
    check_transferred_keys

    # Running handshake test script based on machine type selected
    if [ $machine_type == "Server" ]; then

        # Storing client IP in environment var
        export CLIENT_IP="$machine_ip"

        # Running test script
        $test_scripts_path/oqsprovider-test-server.sh 
        #>> "$root_dir/server-test-output.txt" - uncomment to save output for debugging

    else
    
        # Storing server IP in environment var
        export SERVER_IP="$machine_ip"

        # Outputting current task to the terminal
        echo -e "\n####################################"
        echo "Performing TLS Handshake Tests"
        echo -e "####################################\n"

        # Running handshake test script
        $test_scripts_path/oqsprovider-test-client.sh
        #>> "$root_dir/client-test-output.txt" - uncomment to save output for debugging

        # Outputting TLS Speed test task to the terminal if machine is client
        echo -e "\n##########################"
        echo "Performing TLS Speed Tests"
        echo -e "##########################\n"
        
        # Running OQS-Provider speed test script
        $test_scripts_path/oqsprovider-test-speed.sh
    
    fi

}

#-------------------------------------------------------------------------------------------------------------------------------
function main() {
    # Main function for controlling OQS-Provider TLS performance testing

    # Set the default global flag variables
    custom_control_time_flag="False"
    disable_control_sleep="False"

    # Set default TCP port values
    server_control_port="25000"
    client_control_port="25001"
    s_server_port="4433"

    # Parse script flags if there are any
    if [[ $# -gt 0 ]]; then
        parse_script_flags "$@"
    fi

    # Setting up the base environment for the test suite
    setup_base_env

    # Getting test options and perform tests 
    configure_test_options
    run_tests

    # Cleaning the environment
    clean_environment

}
main "$@"