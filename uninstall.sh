#!/bin/bash

#Copyright (c) 2023 Callum Turino
#SPDX-License-Identifier: MIT

# Script for controlling the Liboqs benchmark testing, it takes in the test parameters and call the relevant test scripts

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
                echo -e "\All Libraries Uninstalled"
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
    # Function for  building the specified test suite

    echo "########################"
    echo "Uninstall Utility Script"
    echo -e "########################\n"

    select_uninstall_mode
    
}
main