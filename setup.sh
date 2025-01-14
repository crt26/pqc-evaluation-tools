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
openssl_path="$libs_dir/openssl_3.2"
liboqs_path="$libs_dir/liboqs"
oqs_provider_path="$libs_dir/oqs-provider"

# Declaring global source-code path files
liboqs_source="$tmp_dir/liboqs-source"
oqs_provider_source="$tmp_dir/oqs-provider-source"
openssl_source="$tmp_dir/openssl-3.2.1"

# Setting Global flag variables
install_type=0 # 0=Liboqs-only, 1=liboqs+OQS-Provider, 2=OQS-Provider-only

#-------------------------------------------------------------------------------------------------------------------------------
function get_reinstall_choice() {
    
    # Check if user would like to reinstall libs
    while true; do
        echo -e "\nPrevious Install Detected!!"
        read -p "would you like to reinstall? (y/n):" user_input

        case $user_input in

            [Yy]* )
                echo -e "Deleting old files and reinstalling...\n"
                break;;

            [Nn]* )
                echo "Will not reinstall, exiting setup script"
                exit 0
                break;;

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

    # Check if libs have already been installed based on install type selected
    case $install_type in

        0)
            if [ -d "$liboqs_path" ]; then
                get_reinstall_choice
            fi
            ;;

        1)
            if [ -d "$liboqs_path" ] || [ -d "$oqs_provider_path" ]; then
                get_reinstall_choice
            fi
            ;;

        2)
            if [ -d "$oqs_provider_path" ]; then
                get_reinstall_choice
            fi
            ;;

    esac

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
        sudo apt-get update && sudo apt upgrade -y
        sudo apt-get install -y "${not_installed[@]}"
    fi

    # Installing needed python modules for testing tools
    echo "Checking Python Dependency Modules..."
    pip install pandas --break-system-packages
    pip install matplotlib --break-system-packages
    pip install jinja2 --break-system-packages
    pip install tabulate --break-system-packages

    # Determine location of Python3 binary
    if [ -x "$(command -v python3)" ]; then
        python_bin="python3" 
    else
        python_bin="python"
    fi

    echo "Dependency checks complete"

}

#-------------------------------------------------------------------------------------------------------------------------------
function handle_oqs_version() {
    # Function for setting the version of the OQS libraries to be used in the setup process. This is to allow
    # the user to set the version to the version last tested by the development team or to default to the latest version available. The 
    # function will only be called if the "safe-setup" argument is passed with the setup script.

    # Check to see if user has passed argument to script
    local script_arg="$1"

    if [ -n "$script_arg" ]; then
    
        # Check if the argument passed is valid and set the version of the OQS libraries to be used
        if [ "$script_arg" == "--safe-setup" ]; then
            echo -e "NOTICE: Safe-Setup selected, using the last tested versions of the OQS libraries\n"
            use_tested_version=1
    
        else

            # Outputting argument error and help message
            echo -e "\nERROR: Argument Passed to setup script is invalid: $script_arg"
            echo -e "If you are trying to use the last tested versions of the OQS libraries, please use the --safe-setup argument when calling the script\n"
            exit 1

        fi

    else
        # Configuring the setup script to use the latest version of the OQS libraries
        use_tested_version=0

    fi
    
}

#-------------------------------------------------------------------------------------------------------------------------------
function openssl_build() {
    # Function for building the required version of OpenSSL (3.2.1) for the testing tools

    # Setting thread count for build and Declaring conf file changes array
    threads=$(nproc)

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

        # Outputting current task to terminal
        echo -e "\n######################################"
        echo "Downloading and Building OpenSSL-3.2.1"
        echo -e "######################################\n"

        # Getting required version of openssl and extracting
        wget -O "$tmp_dir/openssl-3.2.1.tar.gz" https://www.openssl.org/source/openssl-3.2.1.tar.gz
        tar -xf "$tmp_dir/openssl-3.2.1.tar.gz" -C $tmp_dir
        rm "$tmp_dir/openssl-3.2.1.tar.gz"

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

        if [[ "$test_output" != "OpenSSL 3.2.1 30 Jan 2024 (Library: OpenSSL 3.2.1 30 Jan 2024)" ]]; then
            echo -e "\n\nERROR: installing required OpenSSL version failed, please verify install process"
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

        # Ensuring clean build path
        if [ -d "$liboqs_path" ]; then 
            sudo rm -r "$liboqs_path"
        fi
        mkdir -p $liboqs_path

        # Outputting Current Task  
        echo -e "\n#################################"
        echo "Downloading and Installing Liboqs"
        echo -e "#################################\n"

        # Cloning liboqs library repos based on version selected
        if [ "$use_tested_version" -eq 1 ]; then

            # Clone Liboqs and checkout to the latest tested version
            git clone https://github.com/open-quantum-safe/liboqs.git $liboqs_source
            cd $liboqs_source && git checkout "d93a431aaf9ac929f267901509e968a5727c053c"
            cd $root_dir

        else
            # Clone latest Liboqs version
            git clone https://github.com/open-quantum-safe/liboqs.git $liboqs_source
        
        fi
        
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
            echo -e "ERROR: Unsupported System Detected - Manual Build Required!\n"
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
    echo -e "\n#######################################"
    echo "Downloading and Installing OQS-Provider"
    echo -e "#######################################\n"

    # Cloning OQS-Provider library repos based on version selected
    if [ "$use_tested_version" -eq 1 ]; then

        # Clone OQS-Provider and checkout to the latest tested version
        git clone https://github.com/open-quantum-safe/oqs-provider.git $oqs_provider_source >> /dev/null
        cd $oqs_provider_source && git checkout "2cdbc17e149cc7fda3fdd8c355a49581625acbad"
        cd $root_dir

    else

        # Clone latest OQS-Provider version
        git clone https://github.com/open-quantum-safe/oqs-provider.git $oqs_provider_source >> /dev/null
    
    fi

    # Enabling all disabled signature algorithms before building
    export LIBOQS_SRC_DIR="$liboqs_source"
    cp "$root_dir/modded-lib-files/generate.yml" "$oqs_provider_source/oqs-template/generate.yml"
    cd $oqs_provider_source
    /usr/bin/python3 $oqs_provider_source/oqs-template/generate.py
    cd $root_dir

    # Building OQS-Provider library
    cmake -S $oqs_provider_source -B "$oqs_provider_path" \
        -DCMAKE_INSTALL_PREFIX="$oqs_provider_path" -DOPENSSL_ROOT_DIR="$openssl_path" -Dliboqs_DIR="$liboqs_path/lib/cmake/liboqs"

    cmake --build "$oqs_provider_path" -- -j $(nproc)
    cmake --install "$oqs_provider_path"

    echo "OQS-Provider Install Complete"

}

#-------------------------------------------------------------------------------------------------------------------------------
function main() {
    # Function for building the specified test suite

    # Determine which versions of the OQS libraries are to be used
    handle_oqs_version "$1"

    # Getting setup options from user
    while true; do

        # Outputting options to user and getting input
        echo -e "\nPlease Select one of the following build options"
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

                # Setting install type, setting up dirs, and install dependencies
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

                break;;
            
            2)
                # Outputting selection choice
                echo -e "\n########################################"
                echo "Liboqs and OQS-Provider Install Selected"
                echo -e "########################################\n"

                # Setting install type, setting up dirs, and install dependencies
                install_type=1
                configure_dirs
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
                break;;

            3)
                # Outputting selection choice
                echo -e "\n##################################"
                echo "OQS-Provider Only Install Selected"
                echo -e "##################################\n"
                
                # Setting install type, setting up dirs, and install dependencies
                install_type=2
                configure_dirs
                dependency_install

                # Building OpenSSL 3.2.1
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
                break;;

            4)
                echo "Exiting Setup!"
                exit 1
                ;;

            *)
                echo "Invalid option, please select valid option value (1-4)"
                ;;

        esac
    
    done

    # Outputting there was an issue with the python utility script that creates the alg-list files
    if [ "$py_exit_status" -ne 0 ]; then
        echo -e "\nERROR: creating algorithm list files failed, please verify both setup and python scripts and rerun setup!!!"
        echo -e "If the issue persists, you may want to consider re-cloning the repo and rerunning the setup script\n"
    
    elif [ -z "$py_exit_status" ]; then
        echo -e "\nThe Python get_algorithms script did not return an exit status, please verify the script and rerun setup\n"
    fi

    # Outputting setup complete message
    echo -e "\n\nSetup complete, completed builds can be found in the builds directory"

}
main "$@"