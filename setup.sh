#!/bin/bash

#Copyright (c) 2023 Callum Turino
#SPDX-License-Identifier: MIT

# Setup script for the automated PQC benchmark testing tools, the script provides various setup options
# depending on the need of the user. The script will generate the needed directories and also install the 
# required dependency packages based on the system the tools are being setup on.

#------------------------------------------------------------------------------
# Getting Global Dir Variables
root_dir=$(pwd)
scripts_dir="$root_dir/build-scripts"
echo $root_dir

#------------------------------------------------------------------------------
function dependency_install() {
    # Function for checking if there any missing dependencies required for the testing

    # Check for missing dependency packages
    packages=(git astyle cmake gcc ninja-build libssl-dev python3-pytest python3-pytest-xdist unzip xsltproc doxygen graphviz python3-yaml python3-pip valgrind libtool make net-tools)
    not_installed=()

    for package in "${packages[@]}"; do
        if ! dpkg -s "$package" >/dev/null 2>&1; then
            not_installed+=("$package")
        fi
    done

    # Install any missing dependency packages
    if [[ ${#not_installed[@]} -ne 0 ]]; then
        sudo apt-get update && sudo apt upgrade -y
        sudo apt-get install -y "${not_installed[@]}"
    fi

    # Installing needed python modules for testing tools
    pip install pandas
    pip install matplotlib
    pip install jinja2
    pip install tabulate

}

#------------------------------------------------------------------------------
function get_liboqs_version() {
    # Function for getting which version of the liboqs should be used
    # for the liboqs performance testing from the user

    # Getting the required version from the user
    while true; do

        # Ask user which version of liboqs they want to use
        echo -e "\nWhich version of liboqs do you want to use?"
        echo "1 - Version 0.7.2"
        echo "2 - Version 0.8"
        read -p "Enter your choice (1-2): " version_number

        # Write choice to flag file
        case "$version_number" in
            1)
                echo "0" > "$root_dir/alg-lists/version-flag.txt"
                break
                ;;
            2)
                echo "1" > "$root_dir/alg-lists/version-flag.txt"
                break
                ;;
            *)
                echo "Invalid option, please select a valid option value (1-2)"
                ;;
        esac
    
    done

}

#------------------------------------------------------------------------------
function configure_dirs() {
    # Function for creating the required directories for the automated tools
    # alongside setting the root directory path tmp file

    # Creating tmp dir and setting root dir path tmp file
    if [ -d "$root_dir/tmp" ]; then
        echo "$root_dir" > "$root_dir/tmp/install_path.txt"
    else
        mkdir -p "$root_dir/tmp"
        echo "$root_dir" > "$root_dir/tmp/install_path.txt"
    fi

    # Creating build directory and removing old if needed
    if [ -d "$root_dir/builds" ]; then
        rm -rf "$root_dir/builds"
    fi
    mkdir -p "$root_dir/builds"

    # Creating dependency libs directory and removing old if needed
    if [ -d "$root_dir/dependency-libs" ]; then
        rm -rf "$root_dir/dependency-libs"
    fi
    mkdir -p "$root_dir/dependency-libs"

}

#------------------------------------------------------------------------------
function main() {
    # Function for  building the specified test suite

    # Configuring needed directories
    configure_dirs

    # Loop for setup option selection
    while true; do

        # Outputting options to user and getting input
        echo -e "\nPlease Select one of the following build options"
        echo "1 - Build Liboqs Library Only"
        echo "2 - Build OQS-OpenSSL Library Only"
        echo "3 - Build Both Liboqs and OQS-OpenSSL Libraries"
        echo "4 - Exit Setup"
        read -p "Enter your choice (1-3): " user_opt

        # Determining action from user input
        case "$user_opt" in 

            1)
                
                get_liboqs_version
                echo "Building Liboqs..."
                dependency_install
                $scripts_dir/./suite-build.sh -l
                break
                ;;
            
            2)
                echo "Building OQS-OpenSSL..."
                echo "$script_dir"
                dependency_install
                $scripts_dir/suite-build.sh -o
                break
                ;;

            3)
                get_liboqs_version
                echo "Building Full Test Suite..."
                dependency_install
                $scripts_dir/./suite-build.sh -a
                break
                ;;
            4)
                echo "Exiting Setup!"
                exit 1
                ;;
            *)
                echo "Invalid option, please select valid option value (1-4)"
                ;;
        esac
    
    done

    # Outputting setup complete message
    echo -e "\n\nSetup complete, completed builds can be found in the builds directory"

}
main
