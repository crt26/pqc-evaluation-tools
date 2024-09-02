#!/bin/bash

#Copyright (c) 2024 Callum Turino
#SPDX-License-Identifier: MIT

# This is a utility script for uninstalling the OQS-OpenSSL libraries from the system. 
# The script will remove the liboqs, OQS-Provider, and OpenSSL 3.2.1 libraries from the system.

#------------------------------------------------------------------------------
# Declaring global main dir path variables
root_dir=$(pwd)
dependency_dir="$root_dir/dependency-libs"
libs_dir="$root_dir/lib"
tmp_dir="$root_dir/tmp"
test_data_dir="$root_dir/test-data"

# Declaring global library path files
open_ssl_path="$libs_dir/openssl_3.2"
liboqs_path="$libs_dir/liboqs"
oqs_openssl_path="$libs_dir/oqs-openssl"

# Declaring global source-code path files
liboqs_source="$tmp_dir/liboqs-source"
oqs_openssl_source="$tmp_dir/oqs-openssl-source"
openssl_source="$tmp_dir/openssl-3.2.1"

#------------------------------------------------------------------------------
function select_uninstall_mode() {
    # Function for selecting the uninstall option for the currently installed OQS libraries

    # Loop for setup option selection
    while true; do

        # Outputting options to user and getting input
        echo -e "\nPlease Select one of the following uninstall options"
        echo "1 - Uninstall Liboqs Library Only"
        echo "2 - Uninstall OQS-Provider Library only"
        echo "3 - Uninstall OpenSSL 3.2.1 Only"
        echo "4 - Uninstall all Libraries"
        echo "5 - Exit Setup"
        read -p "Enter your choice (1-5): " user_opt

        # Determining action from user input
        case "$user_opt" in 

            1)
                # Uninstall liboqs only
                rm -rf "$liboqs_path"
                echo -e "\nLiboqs Uninstalled"
                break;;
            
            2)
                # Uninstal OQS-Provider only
                rm -rf "$oqs_openssl_path"
                echo -e "\OQS-Provider Uninstalled"
                break;;

            3)
                # Uninstall OpenSSL 3.2.1 only
                rm -rf "$open_ssl_path"
                echo -e "\OpenSSL 3.2.1 Uninstalled"
                break;;

            4)
                # Uninstall all libs
                rm -rf "$libs_dir" && rm -rf "$tmp_dir" && rm -rf "$dependency_dir"
                echo -e "\nAll Libraries Uninstalled"
                break;;

            5)
                echo "Exiting Setup!"
                exit 1
                ;;

            *)
                echo "Invalid option, please select valid option value (1-4)"
                ;;
            
        esac

    done

}

#------------------------------------------------------------------------------
function main() {
    # Main function for controlling the uninstall utility script

    # Outputting script title to the terminal
    echo "########################"
    echo "Uninstall Utility Script"
    echo -e "########################\n"

    # Calling the function that handles the uninstall mode selection and execution
    select_uninstall_mode
    
}
main