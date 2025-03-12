#!/bin/bash

# Copyright (c) 2025 Callum Turino
# SPDX-License-Identifier: MIT

# Setup script for the automated PQC benchmark testing tools, the script provides various setup options
# depending on the need of the user. The script will generate the needed directories and also install the 
# required dependency packages based on the system the tools are being setup on.

#-------------------------------------------------------------------------------------------------------------------------------
# Declaring global main dir path variables
root_dir=$(pwd)
dependency_dir="$root_dir/dependency-libs"
libs_dir="$root_dir/lib"
tmp_dir="$root_dir/tmp"
test_data_dir="$root_dir/test-data"
alg_lists_dir="$test_data_dir/alg-lists"
util_scripts="$root_dir/scripts/utility-scripts"

# Declaring global library path files
openssl_path="$libs_dir/openssl_3.4"
liboqs_path="$libs_dir/liboqs"
oqs_provider_path="$libs_dir/oqs-provider"

# Declaring global source-code path files
liboqs_source="$tmp_dir/liboqs-source"
oqs_provider_source="$tmp_dir/oqs-provider-source"
openssl_source="$tmp_dir/openssl-3.4.1"

# Setting Global flag variables
install_type=0 # 0=Liboqs-only, 1=Liboqs+OQS-Provider, 2=OQS-Provider-only

#-------------------------------------------------------------------------------------------------------------------------------
function output_help_message() {
    # Helper function for outputting the help message to the user when called or when incorrect arguments are passed

    # Output the supported options and their usage to the user
    echo "Usage: setup.sh [options]"
    echo "Options:"
    echo "  --safe-setup                  Use the last tested versions of the OQS libraries"
    echo "  --set-speed-new-value=[int]   Set a new value to be set for the hardcoded MAX_KEM_NUM/MAX_SIG_NUM values in the OpenSSL speed.c file"
    echo "  --help                        Display the help message"

}

#-------------------------------------------------------------------------------------------------------------------------------
function parse_args() {

    # Check if the help flag is passed at any position
    if [[ "$*" =~ --help ]]; then
        output_help_message
        exit 0
    fi

    # Check if custom control port flags have been passed to the script
    while [[ $# -gt 0 ]]; do

        case "$1" in

            --safe-setup)

                # Output the safe setup message to the user and set the use_tested_version flag
                echo -e "[NOTICE] - Safe-Setup selected, using the last tested versions of the OQS libraries\n"
                use_tested_version=1
                shift
                ;;

            --set-speed-new-value=*)

                # Set the user-defined speed flag and value
                user_defined_speed_flag=1
                user_defined_speed_value="${1#*=}"

                # Ensure that the user-defined value is a valid integer if the user-defined speed flag is set
                if [ "$user_defined_speed_flag" -eq 1 ] && ! [[ "$user_defined_speed_value" =~ ^[0-9]+$ ]]; then
                    echo -e "[ERROR] - The user-defined speed value must be a valid integer, please verify the value and rerun the setup script\n"
                    output_help_message
                    exit 1
                fi

                shift
                ;;

            *)
                echo "[ERROR] - Unknown option: $1"
                output_help_message
                exit 1
                ;;

        esac

    done

}

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
function configure_dirs() {
    # Function for creating the required directories for the automated tools alongside setting the root directory path tmp file

    # Declaring directory check array
    required_dirs=("$libs_dir" "$dependency_dir" "$oqs_provider_source" "$tmp_dir" "$test_data_dir" "$alg_lists_dir")

    # Set the default value for the previous install flag
    previous_install=0

    # Check if libs have already been installed based on install type selected
    case $install_type in

        0)
            if [ -d "$liboqs_path" ]; then
                previous_install=1
            fi
            ;;

        1)
            if [ -d "$liboqs_path" ] || [ -d "$oqs_provider_path" ]; then
                previous_install=1
            fi
            ;;

        2)
            if [ -d "$oqs_provider_path" ]; then
                previous_install=1
            fi
            ;;

    esac

    # If a previous install is detected, get the user choice for reinstalling the libraries
    if [ "$previous_install" -eq 1 ]; then

        # Output warning message and get the user choice for reinstalling the libraries
        echo -e "\n[WARNING] - Previous Install Detected!!"
        get_user_yes_no "Would you like to reinstall the libraries?"

        # Continue with the setup or exit based on the user choice
        if [ "$user_y_n_response" -eq 1 ]; then
            echo -e "Deleting old files and reinstalling...\n"
        else
            echo "Will not reinstall, exiting setup script..."
            exit 0
        fi

    fi

    # Removing old dirs depending on install type
    for dir in "${required_dirs[@]}"; do
        
        # Check if dir exists and removes for clean install
        if [ -d "$dir" ]; then
            
            # If Liboqs is installed and user chooses install type 2, remove only OQS-Provider lib dir and not liboqs_dir
            if [ "$dir" == "$libs_dir" ] && [ "$install_type" -eq 2 ]; then
                rm -rf "$oqs_provider_path" && mkdir -p "$oqs_provider_path"

            elif [ "$dir" == "$tmp_dir" ] && [ "$install_type" -eq 2 ]; then 
                rm -rf "$oqs_provider_path"

            else
                rm -rf "$dir" && mkdir -p "$dir"
                
            fi

        else
            rm -rf "$dir" && mkdir -p "$dir"
        fi

    done

    # Create the hidden pqc_eval_dir_marker.tmp file that is used by the test scripts to determine the root directory path
    touch "$root_dir/.pqc_eval_dir_marker.tmp"

}

#-------------------------------------------------------------------------------------------------------------------------------
function configure_oqs_provider_build() {
    # Function for configuring the OQS-Provider build process based on the user input

    # Declare the default OQS-Provider build flag values
    oqs_enable_algs="false"
    oqs_enable_encoders="false"

    # Outputting the current task to the terminal
    echo -e "\nConfiguring Optional OQS-Provider Build Options:\n"

    # Determine if the user wishes to enable all disabled signature algorithms in the OQS-Provider library
    get_user_yes_no "Would you like to enable all the digital signature algorithms in the OQS-Provider library that are disabled by default?"

    # Set the enable_algs flag based on the user response to later be used in the OQS-Provider build function
    if [ "$user_y_n_response" -eq 1 ]; then
        oqs_enable_algs="true"
    else
        oqs_enable_algs="false"
    fi

    # Prompt the user to ask if they wish to enable the KEM encoders option in the OQS-Provider build
    get_user_yes_no "Would you like to enable the KEM encoders option in the OQS-Provider build?"

    # Set the OQS-Provider build flags based on the user input
    if [ "$oqs_enable_algs" == "true" ]; then
        encoder_flag="ON"
    else
        encoder_flag="OFF"
    fi

}

#-------------------------------------------------------------------------------------------------------------------------------
function download_libraries() {
    # Function for downloading the required versions of the dependencies libraries (OpenSSL, Liboqs, OQS-Provider)

    # Output the current task to the terminal
    echo -e "\n##############################"
    echo "Downloading Required Libraries"
    echo -e "##############################\n"

    # Downloading OpenSSL 3.4.1 and extracting into temp dir
    wget -O "$tmp_dir/openssl-3.4.1.tar.gz" https://github.com/openssl/openssl/releases/download/openssl-3.4.1/openssl-3.4.1.tar.gz
    tar -xf "$tmp_dir/openssl-3.4.1.tar.gz" -C $tmp_dir
    rm "$tmp_dir/openssl-3.4.1.tar.gz"

    # Ensure that the OpenSSL source directory is present before continuing
    if [ ! -d "$openssl_source" ]; then
        echo -e "\n[ERROR] - The OpenSSL source directory could not be found after downloading, please verify the installation and rerun the setup script"
        exit 1
    fi

    # Download the Liboqs library based on the user_opt selected
    if [ "$user_opt" == "1" ] || [ "$user_opt" == "2" ]; then

        # Cloning liboqs library repos based on version selected
        if [ "$use_tested_version" -eq 1 ]; then

            # Clone Liboqs and checkout to the latest tested version
            git clone https://github.com/open-quantum-safe/liboqs.git $liboqs_source
            cd $liboqs_source && git checkout "f4b96220e4bd208895172acc4fedb5a191d9f5b1"
            cd $root_dir

        else

            # Clone latest Liboqs version
            git clone https://github.com/open-quantum-safe/liboqs.git $liboqs_source
        
        fi

        # Ensure that the liboqs source directory is present before continuing
        if [ ! -d "$liboqs_source" ]; then
            echo -e "\n[ERROR] - The Liboqs source directory could not be found after downloading, please verify the installation and rerun the setup script"
            exit 1
        fi

    fi

    # Download the OQS-Provider library based on the user_opt selected
    if [ "$user_opt" == "2" ] || [ "$user_opt" == "3" ]; then

        # Cloning OQS-Provider library repos based on version selected
        if [ "$use_tested_version" -eq 1 ]; then

            # Clone OQS-Provider and checkout to the latest tested version
            git clone https://github.com/open-quantum-safe/oqs-provider.git $oqs_provider_source >> /dev/null
            cd $oqs_provider_source && git checkout "ec1e8431f92b52e5d437107a37dbe3408649e8c3"
            cd $root_dir

        else

            # Clone latest OQS-Provider version
            git clone https://github.com/open-quantum-safe/oqs-provider.git $oqs_provider_source >> /dev/null
        
        fi

        # Ensure that the OQS-Provider source directory is present before continuing
        if [ ! -d "$oqs_provider_source" ]; then
            echo -e "\n[ERROR] - The OQS-Provider source directory could not be found after downloading, please verify the installation and rerun the setup script"
            exit 1
        fi

    fi

}

#-------------------------------------------------------------------------------------------------------------------------------
function dependency_install() {
    # Function for checking if there any missing dependencies required for the testing

    # Outputting current task
    echo -e "\n############################"
    echo "Performing Dependency Checks"
    echo -e "############################\n"

    # Check for missing dependency packages
    echo "Checking System Packages Dependencies..."
    packages=(
        "git" "astyle" "cmake" "gcc" "ninja-build" "libssl-dev" "python3-pytest" "python3-pytest-xdist" 
        "unzip" "xsltproc" "doxygen" "graphviz" "python3"-yaml "valgrind" "libtool" "make" "net-tools" "python3-pip" "netcat-openbsd"
    )
    not_installed=()

    for package in "${packages[@]}"; do
        if ! dpkg -s "$package" >/dev/null 2>&1; then
            not_installed+=("$package")
        fi
    done

    # Install any missing dependency packages
    if [[ ${#not_installed[@]} -ne 0 ]]; then
        sudo apt-get update && sudo apt-get upgrade -y
        sudo apt-get install -y "${not_installed[@]}"
    fi

    # Determine which python packages are needing to be installed
    echo "Checking Python Dependencies..."
    required_pip_packages=("pandas" "jinja2" "tabulate")
    missing_pip_packages=()

    for package in "${required_pip_packages[@]}"; do
        if ! python3 -c "import $package" 2>/dev/null; then
            missing_pip_packages+=("$package")
        fi
    done

    # Check if any packages are missing before checking pip install functionality
    if [[ ${#missing_pip_packages[@]} -ne 0 ]]; then

        # Capture the output of the pip install for error checking
        pip_output=$(pip install 2>&1)
        exit_status=$?

        # Check if pip is functioning correctly and if the break system packages flag is needed
        if [ "$exit_status" -ne 0 ]; then

            # Determine the cause of the pip failure
            if echo "$pip_output" | grep -q "error: externally-managed-environment"; then

                # Output the cause to the user and determine if they wish to use the break system packages flag
                echo -e "\nNOTICE: This version of pip requires that either virtual environments be used or the packages be installed system-wide"
                echo -e "This project does not currently support automatic setup of virtual environments.\n"
                
                # Output the options to the user
                echo "Please select one of the following options to handle missing pip packages:"
                echo "1. Use the --break-system-packages flag to install packages system-wide."
                echo "2. Exit the setup script and manually install the required packages before retrying."

                # Get the user choice for using the break system packages flag
                while true; do

                    read -p "Please Select from the above options (1/2): " user_input

                    case $user_input in

                        1 )
                            echo "Proceeding with system-wide installation using --break-system-packages..."
                            export PIP_BREAK_SYSTEM_PACKAGES=1
                            break
                            ;;

                        2 )
                            echo -e "Exiting setup script, please handle the install of the following pip packages manually:"
                            echo "${missing_pip_packages[@]}"
                            exit 1
                            ;;

                        * )
                            echo -e "Invalid selection. Please enter 1 or 2.\n"
                            ;;

                    esac

                done

            elif echo "$pip_output" | grep -q 'ERROR: You must give at least one requirement to install (see "pip help install")'; then
                # No need to do anything as pip is functioning correctly, as it supports the installing to the local user installation
                # this check just makes sure that this expected error from the pip install is ignored and does get caught by the else statement
                :

            else
                echo -e "\n[ERROR] - pip is not functioning correctly, please verify the installation and rerun the setup script"
                exit 1
            
            fi
        
        fi
        
        # Installing the missing pip packages
        for package in "${missing_pip_packages[@]}"; do
            pip install "$package"
        done
    
    else
        echo "All required Python packages are installed and are accessible in the current environment"

    fi

    # Determine location of Python3 binary
    if [ -x "$(command -v python3)" ]; then
        python_bin="python3" 
    else
        python_bin="python"
    fi

    echo "Dependency checks complete"

    # Downloading the required dependency libraries
    download_libraries

}

#-------------------------------------------------------------------------------------------------------------------------------
function set_new_speed_values() {
    # Helper function for setting the new values for the hardcoded MAX_KEM_NUM/MAX_SIG_NUM values in the OpenSSL speed.c file

    # Set the passed variables to local variables
    local passed_filepath="$1"
    local passed_value="$2"

    # Modify the speed.c file to increase the MAX_KEM_NUM/MAX_SIG_NUM values
    sed -i "s/#define MAX_SIG_NUM [0-9]\+/#define MAX_SIG_NUM $new_value/g" "$passed_filepath"
    sed -i "s/#define MAX_KEM_NUM [0-9]\+/#define MAX_KEM_NUM $new_value/g" "$passed_filepath"

    # Ensure that the MAX_KEM_NUM/MAX_SIG_NUM values were successfully modified before continuing
    if ! grep -q "#define MAX_SIG_NUM $new_value" "$passed_filepath" || ! grep -q "#define MAX_KEM_NUM $new_value" "$passed_filepath"; then
        echo -e "\n[ERROR] - Modifying the MAX_KEM_NUM/MAX_SIG_NUM values in the speed.c file failed, please verify the setup and run a clean install"
        exit 1
    fi

}

#-------------------------------------------------------------------------------------------------------------------------------
function modify_openssl_src() {
    # Function for modifying the OpenSSL speed.c source code to adjust the MAX_KEM_NUM and MAX_SIG_NUM values

    # Output the current task to the terminal
    echo -e "[NOTICE] - Enable all disabled OQS-Provider algs flag is set, modifying the OpenSSL speed.c file to adjust the MAX_KEM_NUM/MAX_SIG_NUM values...\n"

    # Set the speed.c filepath
    speed_c_filepath="$openssl_source/apps/speed.c"

    # Set the empty variable for the fail output message used in the initial file checks
    fail_output=""

    # Check if the speed.c file is present
    if [ ! -f "$speed_c_filepath" ]; then
        fail_output="1"

    elif ! grep -q "#define MAX_SIG_NUM" "$speed_c_filepath" || ! grep -q "#define MAX_KEM_NUM" "$speed_c_filepath"; then
        fail_output="2"

    fi

    # If a fail output message is present, output the related options for the fail type
    if [ -n "$fail_output" ]; then

        # Output the relevant warning message and info to the the user
        if [ "$fail_output" == "1" ]; then

            # Output the file can not be found warning message to the user
            echo "[WARNING] - The setup script cannot find the speed.c file in the OpenSSL source code."
            echo -e "The setup process can continue, but the TLS speed tests may not work correctly.\n"

        elif [ "$fail_output" == "2" ]; then

            # Output the MAX_KEM_NUM/MAX_SIG_NUM values not found warning message to the user
            echo "[WARNING] - The OpenSSL speed.c file does not contain the MAX_KEM_NUM/MAX_SIG_NUM values and could not be modified."
            echo "The setup script can continue, but as the enable all disabled algs flag is set, the TLS speed tests may not work correctly."
            echo -e "However, the TLS handshake tests will still work as expected.\n"

        fi

        # Output the options to the user and determine the next steps
        get_user_yes_no "Would you like to continue with the setup process?"

        if [ "$user_y_n_response" -eq 1 ]; then
            echo "Continuing setup process..."
            return 0
        else
            echo "Exiting setup script..."
            exit 1
        fi

    fi

    # Extract the default values assigned to the MAX_KEM_NUM/MAX_SIG_NUM variables in the speed.c file
    default_max_kem_num=$(grep -oP '(?<=#define MAX_KEM_NUM )\d+' "$speed_c_filepath")
    default_max_sig_num=$(grep -oP '(?<=#define MAX_SIG_NUM )\d+' "$speed_c_filepath")

    # If the user-defined speed flag is set, use the user-defined value
    if [ "$user_defined_speed_flag" -eq 1 ]; then
        new_value=$user_defined_speed_value
    fi

    # Set the default fallback value and emergency padding value for the MAX_KEM_NUM/MAX_SIG_NUM values in case of automatic detection failure
    fallback_value=200
    emergency_padding=100

    # Determine highest value between the MAX_KEM_NUM and MAX_SIG_NUM values (they should be the same but just in case)
    highest_default_value=$(($default_max_kem_num > $default_max_sig_num ? $default_max_kem_num : $default_max_sig_num))

    # Ensure that the fallback value is greater than the default MAX_KEM_NUM/MAX_SIG_NUM values
    if [ "$highest_default_value" -gt "$fallback_value" ]; then

        # Set the emergency fallback value and emergency value
        fallback_value=$((highest_default_value + emergency_padding))

        # Warn the user this has happened before continuing the setup process
        echo "[WARNING] - The default fallback value for the MAX_KEM_NUM/MAX_SIG_NUM values is less than the default values in the speed.c file."
        echo -e "The new fallback value with an emergency padding of $emergency_padding is $fallback_value.\n"
        sleep 5

    fi

    # If the user-defined value is set, check that the supplied value is not lower than the current default values in the speed.c file
    if [ "$user_defined_speed_flag" -eq 1 ] && [ "$new_value" -lt "$highest_default_value" ]; then

        # Output the warning message to the user and get their choice for continuing with the setup process
        echo -e "\n[WARNING] - The user-defined new value for the MAX_KEM_NUM/MAX_SIG_NUM variables are less than the default values in the speed.c file."
        echo "The current values in the speed.c file is MAX_KEM_NUM: $default_max_kem_num and MAX_SIG_NUM: $default_max_sig_num."
        echo -e "In this situation, the setup process can use the fallback value of $fallback_value instead of the user defined value of $new_value\n"
        get_user_yes_no "Would you like to continue with the setup process using the default new value of $fallback_value instead?"

        # If fallback should be used, modify the speed.c file to use the fallback value instead otherwise exit the setup script
        if [ "$user_y_n_response" -eq 1 ]; then
            new_value=$fallback_value
        else
            echo "Exiting setup script..."
            exit 1
        fi

    fi

    # Perform automatic adjustment or user define adjustment of the MAX_KEM_NUM/MAX_SIG_NUM values
    if [ "$user_defined_speed_flag" -eq 1 ]; then

        # Set the new values using the user-defined value
        set_new_speed_values "$speed_c_filepath" "$new_value"

    else

        # Determine how much the hardcoded MAX_KEM_NUM/MAX_SIG_NUM values need increased by
        cd "$util_scripts"
        util_output=$($python_bin "get_algorithms.py" "4" 2>&1)
        py_exit_status=$?

        # Check if there were any errors with executing the python utility script
        if [ "$py_exit_status" -eq 0 ]; then

            # Extract the number of algorithms from the Python script output
            alg_count=$(echo "$util_output" | grep -oP '(?<=Total number of Algorithms: )\d+')

            # Check if alg_count is a valid number
            if ! [[ "$alg_count" =~ ^[0-9]+$ ]]; then
                echo "[ERROR] - Failed to extract a valid number of algorithms from the Python script output."
                exit 1
            fi

            # Determine the new value by adding the default value to the number of algorithms found
            new_value=$((highest_default_value + alg_count))

        else

            # Determine what the cause of the error was and output the appropriate message
            if echo "$util_output" | grep -q "File not found:.*"; then

                # Output the error message to the user
                echo "[ERROR] - The Python script that extracts the number of algorithms from the OQS-Provider library could not find the required files."
                echo "Please verify the installation of the OQS-Provider library and rerun the setup script."
                exit 1
            
            elif echo "$util_output" | grep -q "Failed to parse processing file structure:.*"; then

                # Output the warning message to the user
                echo "[WARNING] - There was an issue with the Python script that extracts the number of algorithms from the OQS-Provider library."
                echo "The script returned the following error message: $util_output"

                # Present the options to the user and determine the next steps
                echo -e "It is possible to continue with the setup process using the fallback high values for the MAX_KEM_NUM and MAX_SIG_NUM values.\n"
                get_user_yes_no "Would you like to continue with the setup process using the fallback values ($fallback_value algorithms)?"

                if [ "$user_y_n_response" -eq 1 ]; then
                    echo "Continuing setup process with fallback values..."
                    new_value=$fallback_value
                else
                    echo "Exiting setup script..."
                    exit 1
                fi

            else

                # Output the error message to the user
                echo "[ERROR] - A wider error occurred within the Python get_algorithms utility script. This will cause larger errors in the setup process."
                echo "Please verify the setup environment and rerun the setup script."
                echo "The script returned the following error message: $util_output"
                exit 1

            fi
            
        fi

        # Set the new values using the new_value variable
        set_new_speed_values "$speed_c_filepath" "$new_value"
        
    fi

    # Output success message to the terminal
    echo "[NOTICE] - The MAX_KEM_NUM/MAX_SIG_NUM values in the OpenSSL speed.c file have been successfully modified to $new_value"

}

#-------------------------------------------------------------------------------------------------------------------------------
function openssl_build() {
    # Function for building the required version of OpenSSL (3.4.1) for the testing tools

    # Outputting current task to terminal
    echo -e "\n######################"
    echo "Building OpenSSL-3.4.1"
    echo -e "######################\n"

    # Setting thread count for build and Declaring conf file changes array
    threads=$(nproc)

    # Define the path to the OQS-Provider library and the openssl.cnf file changes
    oqsprovider_path="$oqs_provider_path/lib/oqsprovider.so"
    conf_changes=(
        "[openssl_init]"
        "providers = provider_sect"
        "ssl_conf = ssl_sect"
        "[provider_sect]"
        "default = default_sect"
        "oqsprovider = oqsprovider_sect"
        "[default_sect]"
        "activate = 1"
        "[oqsprovider_sect]"
        "activate = 1"
        "module = $oqs_provider_path/lib/oqsprovider.so"
        "[ssl_sect]"
        "system_default = system_default_sect"
        "[system_default_sect]"
        "Groups = \$ENV::DEFAULT_GROUPS"
    )

    # Check if previous openssl build is present and build if not
    if [ ! -d "$openssl_path" ]; then

        # Modify the speed.c source code if the OQS-Provider library is being built with the enable all disabled algs flag
        if [ "$oqs_enable_algs" == "true" ]; then
            modify_openssl_src
        fi

        # Building required version of OpenSSL in testing-repo directory only
        echo "Building OpenSSL Library"
        cd $openssl_source
        ./config --prefix="$openssl_path" --openssldir="$openssl_path" shared >/dev/null
        make -j $threads >/dev/null
        make -j $threads install >/dev/null
        cd $root_dir
        echo -e "OpenSSL build complete"

        # Check lib dir name before exporting temp path 
        if [[ -d "$openssl_path/lib64" ]]; then
            openssl_lib_path="$openssl_path/lib64"
        else
            openssl_lib_path="$openssl_path/lib"
        fi

        # Exporting openssl lib path for check
        export LD_LIBRARY_PATH="$openssl_lib_path:$LD_LIBRARY_PATH"

        # Testing if the new version has correctly installed
        test_output=$("$openssl_path/bin/openssl" version)

        if [[ "$test_output" != "OpenSSL 3.4.1 11 Feb 2025 (Library: OpenSSL 3.4.1 11 Feb 2025)" ]]; then
            echo -e "\n\n[ERROR] - Installing required OpenSSL version failed, please verify install process"
            exit 1
        fi

        # Modify OpenSSL conf file to include OQS-Provider as a provider
        cd $openssl_path && rm -f openssl.conf && cp "$root_dir/modded-lib-files/openssl.cnf" "$openssl_path/"

        for conf_change in "${conf_changes[@]}"; do
            echo $conf_change >> "$openssl_path/openssl.cnf"
        done

    else
        echo "openssl build present, skipping build"
    fi

}

#-------------------------------------------------------------------------------------------------------------------------------
function enable_pmu() {
    # Function for enabling the ARM PMU and allowing it to be used in user space on Raspberry-Pi

    # Checking if the system is a Raspberry-Pi and installing kernel-headers
    if ! dpkg -s "raspberrypi-kernel-headers" >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install raspberrypi-kernel-headers
    fi

    # Enabling user access PMU
    echo -e "\nEnabling ARM PMU\n"
    cd $libs_dir
    git clone --branch main https://github.com/mupq/pqax.git
    cd "$libs_dir/pqax/enable_ccr"
    make
    make_status=$? 
    make install
    cd $root_dir

    # Setting enabled PMU flag
    if [ "$make_status" -eq 0 ]; then
        enabled_pmu=1
    else
        enabled_pmu=0
    fi

}

#-------------------------------------------------------------------------------------------------------------------------------
function liboqs_build() {
    # Function for building OQS Liboqs library, will build relevant version based on system architecture

    # Building liboqs if install type is 0 or 1
    if [ "$install_type" -eq 0 ] || [ "$install_type" -eq 1 ]; then

        # Outputting Current Task  
        echo -e "\n#################"
        echo "Installing Liboqs"
        echo -e "#################\n"

        # Ensuring clean build path
        if [ -d "$liboqs_path" ]; then 
            sudo rm -r "$liboqs_path"
        fi
        mkdir -p $liboqs_path

        # Setting build options based on current system
        if [ "$(uname -m)" = "x86_64" ] && [ "$(uname -s)" = "Linux" ]; then

            # Setting x86 linux build options
            build_options="no-shared linux-x86_64"
            build_flags=""
            threads=$(nproc)

        elif [[ "$(uname -m)" = arm* || "$(uname -m)" == aarch* ]]; then

            # Enabling ARM PMU if needed
            if lsmod | grep -q 'enable_ccr'; then
                echo "The enable_ccr module is already enabled, skipping build."
            else
                enable_pmu
            fi

            # Setting ARM arrch64 build options for pi
            if [ $enabled_pmu -eq 1 ];then
                build_flags="-DOQS_SPEED_USE_ARM_PMU=ON"
            else
                build_flags=""
            fi
            threads=$(nproc)
            
        else
            # Unsupported system error 
            echo -e "[ERROR] - Unsupported System Detected - Manual Build Required!\n"
            exit 1
        fi

        # Replacing test_mem files with modded version
        cp "$root_dir/modded-lib-files/test_sig_mem.c" "$liboqs_source/tests/test_sig_mem.c"
        cp "$root_dir/modded-lib-files/test_kem_mem.c" "$liboqs_source/tests/test_kem_mem.c"

        # Setting up build directory and building liboqs
        cmake -GNinja -DCMAKE_C_FLAGS="$build_flags" -S "$liboqs_source/" -B "$liboqs_path/build" -DCMAKE_INSTALL_PREFIX="$liboqs_path" \
            -DOQS_USE_OPENSSL=ON -DOPENSSL_ROOT_DIR="$openssl_path"

        cmake --build "$liboqs_path/build" -- -j $threads
        cmake --build "$liboqs_path/build" --target install -- -j $threads

        # Creating test-data store dirs
        mkdir -p "$liboqs_path/mem-results/kem-mem-metrics/" && mkdir -p "$liboqs_path/mem-results/sig-mem-metrics/" && mkdir "$liboqs_path/speed-results"

        echo "Liboqs Install Complete"

    fi

}

#-------------------------------------------------------------------------------------------------------------------------------
function oqs_provider_build() {
    # Function for building OQS-Provider library, will build relevant version based on system architecture

    # Cloning required repositories
    echo -e "\n#######################"
    echo "Installing OQS-Provider"
    echo -e "#######################\n"

    # Set the generate.yml filepaths
    backup_generate_file="$root_dir/modded-lib-files/generate.yml"
    oqs_provider_generate_file="$oqs_provider_source/oqs-template/generate.yml"

    # Enabling all disabled signature algorithms before building
    if [ "$oqs_enable_algs" == "true" ]; then

        # Ensure that the generate.yml file is present and determine action based on its presence
        if [ ! -f  "$oqs_provider_generate_file" ]; then

            # Outputting error message and getting user response
            echo -e "\n[WARNING] - The generate.yml file is missing from the OQS-Provider library, it is possible that the library no longer supports this feature"
            get_user_yes_no "Would you like to continue with the setup process anyway?"

            # Determine action based on user response
            if [ "$user_y_n_response" -eq 0 ]; then
                echo -e "Exiting setup script..."
                exit 1
            else
                echo "Continuing setup process..."
                return 0
            fi

        fi

        # Ensure that the generate.yml file still follows the enable: true/enable: false format before proceeding
        if ! grep -q "enable: true" "$oqs_provider_generate_file" || ! grep -q "enable: false" "$oqs_provider_generate_file"; then

            # Outputting error message and getting user response
            echo -e "\n[WARNING] - The generate.yml file in the OQS-Provider library does not follow the expected format"
            echo -e "this setup script cannot automatically enable all disabled signature algorithms\n"
            get_user_yes_no "Would you like to continue with the setup process anyway?"

            # Determine action based on user response
            if [ "$user_y_n_response" -eq 0 ]; then
                echo -e "Exiting setup script..."
                exit 1
            else
                echo "Continuing setup process..."
                return 0
            fi

        fi

        # Modify the generate.yml file to enable all disabled signature algorithms
        sed -i 's/enable: false/enable: true/g' "$oqs_provider_generate_file"

        # Check if the generate.yml file was successfully modified
        if ! grep -q "enable: true" "$oqs_provider_generate_file"; then
            echo -e "\n[ERROR] - Enabling all disabled signature algorithms in the OQS-Provider library failed, please verify the setup and run a clean install"
            exit 1
        fi

        # Run the generate.py script to enable all disabled signature algorithms
        export LIBOQS_SRC_DIR="$liboqs_source"
        cd $oqs_provider_source
        /usr/bin/python3 $oqs_provider_source/oqs-template/generate.py
        cd $root_dir

    fi

    # Building OQS-Provider library
    cmake -S $oqs_provider_source -B "$oqs_provider_path" \
        -DCMAKE_INSTALL_PREFIX="$oqs_provider_path" -DOPENSSL_ROOT_DIR="$openssl_path" \
        -Dliboqs_DIR="$liboqs_path/lib/cmake/liboqs" -DOQS_KEM_ENCODERS="$encoder_flag"

    cmake --build "$oqs_provider_path" -- -j $(nproc)
    cmake --install "$oqs_provider_path"

    echo "OQS-Provider Install Complete"

}

#-------------------------------------------------------------------------------------------------------------------------------
function main() {
    # Function for building the specified test suite

    # Output the welcome message to the terminal
    echo "#################################"
    echo "PQC-Evaluation-Tools Setup Script"
    echo -e "#################################\n"

    # Set the default script wide flag values
    use_tested_version=0
    user_defined_speed_flag=0

    # Parse arguments passed to the script
    if [ "$#" -gt 0 ]; then
        parse_args "$@"
    fi

    # Getting setup options from user
    while true; do

        # Outputting options to user and getting input
        echo "Please Select one of the following build options"
        echo "1 - Build Liboqs Library Only"
        echo "2 - Build OQS-Provider and Liboqs Library"
        echo "3 - Build OQS-Provider Library with previous Liboqs Install"
        echo "4 - Exit Setup"
        read -p "Enter your choice (1-4): " user_opt

        # Determining setup action based on user input
        case "$user_opt" in 

            1)
                # Outputting selection choice
                echo -e "\n############################"
                echo "Liboqs Only Install Selected"
                echo -e "############################\n"

                # Configuring setup environment and installing dependencies
                install_type=0
                configure_dirs
                dependency_install

                # Building libraries and cleaning up
                openssl_build
                liboqs_build
                rm -rf $tmp_dir/*

                # Creating the required alg-list files for testing
                cd "$util_scripts"
                $python_bin "get_algorithms.py" "1"
                py_exit_status=$?
                cd $root_dir

                break
                ;;
            
            2)
                # Outputting selection choice
                echo -e "\n########################################"
                echo "Liboqs and OQS-Provider Install Selected"
                echo -e "########################################\n"

                # Configuring setup environment and installing dependencies
                install_type=1
                configure_dirs
                configure_oqs_provider_build
                dependency_install

                # Building libraries and cleaning up
                openssl_build
                liboqs_build
                oqs_provider_build
                rm -rf $tmp_dir/*

                # Creating the required alg-list files for testing
                cd "$util_scripts"
                $python_bin "get_algorithms.py" "2"
                py_exit_status=$?
                cd $root_dir

                break
                ;;

            3)
                # Outputting selection choice
                echo -e "\n##################################"
                echo "OQS-Provider Only Install Selected"
                echo -e "##################################\n"

                # Configuring setup environment and installing dependencies
                install_type=2
                configure_dirs
                configure_oqs_provider_build
                dependency_install

                # Building OpenSSL 3.4.1
                openssl_build

                # Check if liboqs is present and install if not
                if [ ! -d "$liboqs_path" ]; then
                    echo -e "\n!!!Liboqs not installed, will install now!!!"
                    install_type=1
                    liboqs_build
                fi

                # Re-clone liboqs repo for alg docs if missing as needed for enabling disabled algs in oqs_provider_build
                if [ ! -d "$liboqs_source" ]; then
                    git clone https://github.com/open-quantum-safe/liboqs.git $liboqs_source >/dev/null
                fi

                # Building OQS-Provider
                oqs_provider_build
                rm -rf $tmp_dir/*

                # Check if Liboqs alg-list files are present before deciding which alg-list files need generated
                if [ -f "$alg_lists_dir/kem-algs.txt" ] && [ -f "$alg_lists_dir/sig-algs.txt" ]; then
                    alg_list_flag="3"
                else
                    alg_list_flag="2"
                fi

                # Create the required alg-list files for testing
                cd "$util_scripts"
                $python_bin "get_algorithms.py" "$alg_list_flag"
                py_exit_status=$?
                cd $root_dir

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

    # Configure the flag file the KEM encoders option in the OQS-Provider build for use by the testing scripts
    if [ "$encoder_flag" == "ON" ]; then
        touch "$tmp_dir/kem_encoders_enabled.flag"
    
    elif [ "$encoder_flag" == "OFF" ]; then

        # Remove flag file if present in the tmp directory as the KEM encoders are disabled
        if [ -f "$tmp_dir/kem_encoders_enabled.flag" ]; then
            rm "$tmp_dir/kem_encoders_enabled.flag"
        fi

    fi

    # Outputting there was an issue with the python utility script that creates the alg-list files
    if [ "$py_exit_status" -ne 0 ]; then
        echo -e "\n[ERROR] - creating algorithm list files failed, please verify both setup and python scripts and rerun setup!!!"
        echo -e "If the issue persists, you may want to consider re-cloning the repo and rerunning the setup script\n"
    
    elif [ -z "$py_exit_status" ]; then
        echo -e "\nThe Python get_algorithms script did not return an exit status, please verify the script and rerun setup\n"
    fi

    # Outputting setup complete message
    echo -e "\n\nSetup complete, completed builds can be found in the builds directory"

}
main "$@"