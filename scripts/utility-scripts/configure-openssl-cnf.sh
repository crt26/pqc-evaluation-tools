#!/bin/bash

# Copyright (c) 2025 Callum Turino
# SPDX-License-Identifier: MIT

# This is a utility script used to configure the openssl.cnf file for the OpenSSL library 
# to allow for the generation of post-quantum cryptographic keys. The script is used to 
# comment out the default groups in the configuration file to allow for the use of the scheme groups included with the OQS-Provider library.

#-------------------------------------------------------------------------------------------------------------------------------
function output_help_message() {
    # Helper function for outputting the help message to the user when called or when incorrect arguments are passed

    # Output the supported options and their usage to the user
    echo "Usage: configure-openssl-cnf.sh [options]"
    echo "Options:"
    echo "  0                     Configure OpenSSL for standard mode"
    echo "  1                     Configure OpenSSL for PQC testing mode"
    echo "  --help                Display this help message and exit"

}

#-------------------------------------------------------------------------------------------------------------------------------
function parse_args() {
    # Function for parsing the flags passed to the script when called

    # Check if the help flag is passed at any position
    if [[ "$*" =~ --help ]]; then
        output_help_message
        exit 0
    fi

    # Set the default option selected flag 
    mode_selected="False"

    # Check if custom control port flags have been passed to the script
    while [[ $# -gt 0 ]]; do

        case "$1" in

            0)

                # Set the configure mode if no mode has been yet
                if [ "$mode_selected" == "False" ]; then
                    configure_mode=0
                    mode_selected="True"

                else
                    echo "[ERROR] - Only one mode can be selected at a time"
                    exit 1
                fi

                shift
                ;;

            1)
                # Set the configure mode if no mode has been yet
                if [ "$mode_selected" == "False" ]; then
                    configure_mode=1
                    mode_selected="True"

                else
                    echo "[ERROR] - Only one mode can be selected at a time"
                    exit 1
                fi

                shift
                ;;

            *)
                echo -e "[ERROR] - Invalid argument passed to configure-openssl-cnf.sh"
                output_help_message
                exit 1
                ;;

        esac

    done

}

#-------------------------------------------------------------------------------------------------------------------------------
function setup_base_env() {
    # Function for setting up the basic global variables for the test suite. This includes setting the root directory
    # and the global library paths for the test suite. The function establishes the root path by determining the path of the script and 
    # using this, determines the root directory of the project.

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

    # Declaring global library path files
    openssl_path="$libs_dir/openssl_3.4"
    liboqs_path="$libs_dir/liboqs"
    oqs_provider_path="$libs_dir/oqs-provider"

    # Exporting OpenSSL lib path
    if [[ -d "$openssl_path/lib64" ]]; then
        openssl_lib_path="$openssl_path/lib64"
    else
        openssl_lib_path="$openssl_path/lib"
    fi

    export LD_LIBRARY_PATH="$openssl_lib_path:$LD_LIBRARY_PATH"

}

#-------------------------------------------------------------------------------------------------------------------------------
function configure_conf_statements() {
    # Function for commenting out additional lines in the OpenSSL to temporarily remove the default groups configuration
    # used in testing scripts to allow key generation to be performed

    # Declare required local variables
    local conf_path="$openssl_path/openssl.cnf"

    # Set the configurations based on the configuration mode passed
    if [ "$configure_mode" -eq 0 ]; then

        # Comment out the unnecessary lines for standard configuration
        sed -i 's/ssl_conf = ssl_sect/#ssl_conf = ssl_sect/' $conf_path
        sed -i 's/system_default = system_default_sect/#system_default = system_default_sect/' $conf_path
        sed -i 's/Groups = \$ENV::DEFAULT_GROUPS/#Groups = \$ENV::DEFAULT_GROUPS/' $conf_path

    elif [ "$configure_mode" -eq 1 ]; then 

        # Uncomment configurations for PQC testing
        sed -i 's/^#ssl_conf = ssl_sect/ssl_conf = ssl_sect/' $conf_path
        sed -i 's/^#system_default = system_default_sect/system_default = system_default_sect/' $conf_path
        sed -i 's/^#Groups = \$ENV::DEFAULT_GROUPS/Groups = \$ENV::DEFAULT_GROUPS/' $conf_path

    fi

}

#-------------------------------------------------------------------------------------------------------------------------------
function main() {
    # Main function for controlling the utility script

    # Declare the configuration mode variable
    configure_mode=""

    # Ensure that arguments have been passed to the script and parse them
    if [[ $# -gt 0 ]]; then
        parse_args "$@"

    else
        echo "[ERROR] - No arguments passed to configure-openssl-cnf.sh"
        output_help_message
        exit 1

    fi

    # Setting up the base environment for the test suite
    setup_base_env

    # Call configure conf file function and pass mode
    configure_conf_statements

}
main "$@"