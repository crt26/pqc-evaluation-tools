#!/bin/bash

# Copyright (c) 2025 Callum Turino
# SPDX-License-Identifier: MIT

# This is a utility script for cleaning the various project files produced from compiling and benchmarking. The script 
# provides functionality for either uninstalling the OQS-Provider libraries from the system, clearing the old results and generated TLS keys, or both. 
# When uninstalling, the script will remove the liboqs, OQS-Provider, and OpenSSL 3.4.1 libraries from the system. When clearing the old results and keys,
# the script will remove the old test results and generated keys directories from the test-data directory.

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
    dependency_dir="$root_dir/dependency-libs"
    libs_dir="$root_dir/lib"
    tmp_dir="$root_dir/tmp"
    test_data_dir="$root_dir/test-data"

    # Declaring global library path files
    openssl_path="$libs_dir/openssl_3.4"
    liboqs_path="$libs_dir/liboqs"
    oqs_provider_path="$libs_dir/oqs-provider"

    # Declaring global source-code path files
    liboqs_source="$tmp_dir/liboqs-source"
    oqs_provider_source="$tmp_dir/oqs-provider-source"
    openssl_source="$tmp_dir/openssl-3.4.1"

}

#------------------------------------------------------------------------------
function select_uninstall_mode() {
    # Function for selecting the uninstall option for the currently installed OQS libraries

    echo -e "\n########################"
    echo "Uninstalling Libraries"
    echo -e "########################"

    # Loop for setup option selection
    while true; do

        # Outputting options to user and getting input
        echo -e "\nPlease Select one of the following uninstall options"
        echo "1 - Uninstall Liboqs Library Only"
        echo "2 - Uninstall OQS-Provider Library only"
        echo "3 - Uninstall OpenSSL 3.4.1 Only"
        echo "4 - Uninstall all Libraries"
        echo "5 - Exit Setup"
        read -p "Enter your choice (1-5): " user_opt

        # Determining action from user input
        case "$user_opt" in 

            1)
                # Uninstall Liboqs only
                rm -rf "$liboqs_path"
                echo -e "\nLiboqs Uninstalled"
                break;;
            
            2)
                # Uninstal OQS-Provider only
                rm -rf "$oqs_provider_path"
                echo -e "\nOQS-Provider Uninstalled"
                break;;

            3)
                # Uninstall OpenSSL 3.4.1 only
                rm -rf "$openssl_path"
                echo -e "\nOpenSSL 3.4.1 Uninstalled"
                break;;

            4)
                # Uninstall all dependency libraries
                rm -rf "$libs_dir" && rm -rf "$tmp_dir" && rm -rf "$dependency_dir"
                rm -rf "$root_dir/.pqc_eval_dir_marker.tmp"
                echo -e "\nAll Libraries Uninstalled"
                break;;

            5)
                echo "Exiting Uninstall Script!"
                exit 1
                ;;

            *)
                echo -e "\nInvalid option, please select valid option value (1-4)\n"
                ;;
            
        esac

    done

}

#------------------------------------------------------------------------------
function remove_old_results() {
    # Function for removing old test results and generated keys directories from the test-data directory

    echo -e "\n###############################"
    echo "Clearing Results and TLS Keys"
    echo -e "\n###############################\n"

    # Verify the user definitely wants to remove all results and keys
    while true; do 

        read -p "Are you sure you want to remove all stored results and generated keys? This cannot be reversed if you do not have backup copies! (y/n): " user_input

        # Check if user wants to remove all results and keys
        if [ "$user_input" == "y" ]; then
            break
        elif [ "$user_input" == "n" ]; then
            echo "Exiting Cleaning Script!"
            exit 1
        else
            echo -e "\nInvalid input, please enter 'y' or 'n'\n"
        fi

    done

    # Remove all relevant directories
    rm -rf "$test_data_dir/results"
    rm -rf "$test_data_dir/up-results"
    rm -rf "$test_data_dir/keys"
    rm -rf "$tmp_dir/*"
    echo -e "\nAll results and generated keys cleared\n"

}

#------------------------------------------------------------------------------
function main() {
    # Main function for controlling the uninstall utility script

    # Setting up the base environment for the test suite
    setup_base_env
    
    # Outputting script title to the terminal
    echo "#################################"
    echo "Project Cleaner Utility Script"
    echo "#################################"

    # Determine what clearing action the user would like to perform
    while true; do

        echo -e "\nPlease select what clearing action you would like to perform"
        echo "1 - Uninstall Libraries Only"
        echo "2 - Clear old test results and generated TLS Keys Only"
        echo "3 - Uninstall libraries and clear old test results/generated TLS keys"
        echo "4 - Exit Cleaning Script"
        read -p "Enter your choice (1-4): " user_opt

        # Calling relevant cleaning functions based on user input
        case "$user_opt" in 

            1)
                # Uninstall dependency libraries only
                echo -e "\nOption 1 Selected: Uninstall Libraries Only"
                select_uninstall_mode
                break;;

            2)
                # Clear old test results and generated keys only
                echo -e "\nOption 2 Selected: Clear Old Test Results and Generated TLS Keys"
                remove_old_results
                break;;

            3)
                # Uninstall both OQS libraries and clear old test results and generated keys
                echo -e "\nOption 4 Selected: Uninstall Libraries and Clear Old Test Results/Generated TLS Keys"
                select_uninstall_mode
                remove_old_results
                break;;

            4)
                echo "Exiting Uninstall Script!"
                exit 1
                ;;

            *)
                echo -e "\nInvalid option, please select valid option value (1-4)\n"
                ;;
            
        esac
    
    done
    
}
main