#!/bin/bash

#Copyright (c) 2023 Callum Turino
#SPDX-License-Identifier: MIT

# Setup script for the automated PQC benchmark testing tools, the script provides various setup options
# depending on the need of the user. The script will generate the needed directories and also install the 
# required dependency packages based on the system the tools are being setup on.

#------------------------------------------------------------------------------
# Setting global dir path variables
root_dir=$(pwd)
oqs_source_dir=""
dependency_dir="$root_dir/dependency-libs"
libs_dir="$root_dir/libs"
open_ssl_path=""

# Declaring OQS source code dir paths if needed
liboqs_source="$dependency_dir/liboqs-source"
oqs_openssl_source="$dependency_dir/oqs-openssl-source"
openssl_source="$dependency_dir/openssl_3.2/"

# Setting Global flag variables
liboqs_build_type=0 # 0=only-liboqs, 1=liboqs-for-oqs-openssl,
use_system_openssl=0


#------------------------------------------------------------------------------
function openssl_build() {

    # https://www.openssl.org/source/openssl-3.2.1.tar.gz
    dst_build_path="$dependency_dir/openssl_3.2"

    # Getting reuquired version of openssl and extracting
    wget -O $dependency_dir https://www.openssl.org/source/openssl-3.2.1.tar.gz
    tar -xf "$dependency_dir/openssl_3.2/openssl-3.2.1.tar.gz" $openssl_source


}

#------------------------------------------------------------------------------
function dependency_install() {
    # Function for checking if there any missing dependencies required for the testing

    # Check for missing dependency packages
    packages=(git astyle cmake gcc ninja-build libssl-dev python3-pytest python3-pytest-xdist unzip xsltproc doxygen graphviz python3-yaml valgrind libtool make net-tools)
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

    # Cloning liboqs library repos
    git clone https://github.com/open-quantum-safe/liboqs.git $liboqs_source

    # Checking for correct verison of OpenSSL and if missing installing
    installed_version=$(openssl version | awk '{print $2}')
    minimum_version="3.2.0"

    # Compare the versions
    if [[ "$(printf '%s\n' "$installed_version" "$minimum_version" | sort -V | head -n1)" = "$minimum_version" ]]; then
        # If the installed version is greater than or equal to the minimum version
        use_system_openssl=1
        open_ssl_path="/usr/bin/openssl"
    else
        use_system_openssl=0
        open_ssl_path="$dependency_dir/openssl_3.2"
    fi

}

#------------------------------------------------------------------------------
function configure_dirs() {
    # Function for creating the required directories for the automated tools
    # alongside setting the root directory path tmp file

    # # Creating tmp dir and setting root dir path tmp file
    # if [ -d "$root_dir/tmp" ]; then
    #     echo "$root_dir" > "$root_dir/tmp/install_path.txt"
    # else
    #     mkdir -p "$root_dir/tmp"
    #     echo "$root_dir" > "$root_dir/tmp/install_path.txt"
    # fi

    # Creating build directory and removing old if needed
    if [ -d "$libs_dir" ]; then
        rm -rf $libs_dir
    fi
    mkdir -p $libs_dir

    # Creating dependency libs directory and removing old if needed
    if [ -d "$dependency_dir" ]; then
        rm -rf $dependency_dir
    fi
    mkdir -p $dependency_dir

    # Creating source code files directory and removing old if needed
    if [ -d "$sources_dir" ]; then
        rm -rf $sources_dir
    fi
    mkdir -p $sources_dir

}

#------------------------------------------------------------------------------
function enable_pmu() {
    # Function for enabling the ARM PMU and allowing it to be used in user space on Pi

    # Checking if the system is a Pi and installing kernel-headers
    if ! dpkg -s "raspberrypi-kernel-headers" >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install raspberrypi-kernel-headers
    fi

    #Enabling user access PMU
    echo -e "\nEnabling ARM PMU\n"
    cd $dependency_dir
    git clone --branch main https://github.com/mupq/pqax.git
    cd "$dependency_dir/pqax/enable_ccr" && make && make install

}

#------------------------------------------------------------------------------
function liboqs-build() {
    # Function for building OQS Liboqs library, will build relevant version based on system architecture

    # Setting build dir filepaths based on build type
    if [ "$liboqs_build_type" -eq 0 ]; then

        # Setting path var and removing old liboqs files
        dst_build_path="$libs_dir/liboqs"

        if [ -d "$dst_build_path" ]; then 
            sudo rm -r "$dst_build_path"
        fi
        mkdir $dst_build_path

    else

        # Setting path var and removing old liboqs files
        dst_build_path="$libs_dir/oqs-openssl-build/liboqs"
        
        if [ -d "$dst_build_path" ]; then 
            sudo rm -r "$dst_build_path"
        fi
    
    fi

    # Checking if the liboqs build directories already exist
    if [ -d "$dst_build_path" ]; then
        echo -e "There is a current build available - skipping build\n"
    else

        # Setting build options based on current system
        if [ "$(uname -m)" = "x86_64" ] && [ "$(uname -s)" = "Linux" ]; then 
            # x86 linux build options
            build_options="no-shared linux-x86_64"
            build_flags=""
            threads=$(nproc)

        elif [[ "$(uname -m)" = arm* || "$(uname -m)" == aarch* ]]; then

            #ARM arrch64 build options for pi
            build_options="no-shared linux-aarch64"
            build_flags="-D_OQS_RASPBERRY_PI -DSPEED_USE_ARM_PMU"
            build_flag1="-D_OQS_RASPBERRY_PI"
            build_flag2="-DSPEED_USE_ARM_PMU"
            threads=$(nproc)
            
            # Enabling ARM PMU if needed
            if lsmod | grep -q 'enable_ccr'; then
                echo "The enable_ccr module enabled, skipping build."
            else
                enable_pmu
            fi

        else
            # Unsupported system error 
            echo -e "Unsupported System Detected - Manual Build Required!\n"
            exit 1
        fi

        # Setting up build directory and building liboqs
        cmake -GNinja "$liboqs_source/" -DCMAKE_INSTALL_PREFIX="$dst_build_path" && ninja -j $threads && ninja -j $threads install
        if [ "$liboqs_build_type" -eq 0 ]; then
            mkdir -p "$dst_build_path/mem-results/kem-mem-metrics/" && mkdir -p "$dst_build_path/mem-results/sig-mem-metrics/" && mkdir "$dst_build_path/speed-results"
        fi

    fi

}

#------------------------------------------------------------------------------
function oqs-openssl-build() {
    # Function for building OQS-OpenSSL library, will build relevant version based on system architecture

    # Setting OQS build dir path
    oqs_build_dir="$root_dir/builds/oqs-openssl-build/"

    # Checking if build is already there
    if [ -d "$root_dir/builds/oqs-openssl-build" ]; then 
        echo -e "There is already a OQS-OpenSSL Build Present"
    else

        # Setting build options based on current system
        if [ "$(uname -m)" = "x86_64" ] && [ "$(uname -s)" = "Linux" ]; then 
            # x86 linux build options
            build_options="no-shared linux-x86_64"
            build_flags=""
            threads=6

        elif [[ "$(uname -m)" = arm* || "$(uname -m)" == aarch* ]]; then

            #ARM arrch64 build options for pi
            build_options="no-shared linux-aarch64"
            build_flags="-D_OQS_RASPBERRY_PI -DSPEED_USE_ARM_PMU"
            build_flag1="-D_OQS_RASPBERRY_PI"
            build_flag2="-DSPEED_USE_ARM_PMU"
            threads=4
            
            # Enabling ARM PMU if needed
            if lsmod | grep -q 'enable_ccr'; then
                echo "The enable_ccr module enabled, skipping build."
            else
                enable_pmu
            fi
        fi

        # Cloning needed repos
        mkdir -p "$oqs_build_dir"
        git clone https://github.com/open-quantum-safe/oqs-provider.git "$oqs_build_dir/openssl"
        git clone --branch main https://github.com/open-quantum-safe/liboqs.git "$oqs_build_dir/liboqs"

        # Building Liboqs for OQS-OpenSSL
        mkdir -p "$oqs_build_dir/liboqs/build" && cd "$oqs_build_dir/liboqs/build"
        cmake -DCMAKE_C_FLAGS="$build_flags" -GNinja -DCMAKE_INSTALL_PREFIX="$oqs_build_dir/openssl/oqs" ..
        ninja -j $threads && ninja install

        # Building OQS-OpenSSL
        cd "$oqs_build_dir/openssl"
        ./Configure $build_options -lm
        make -j $threads

        # # Enabling disabled signature algorithms
        # export LIBOQS_DOCS_DIR="$oqs_build_dir/liboqs/docs"
        # cp "$root_dir/modded-liboqs-files/generate.yml" "$oqs_build_dir/openssl/oqs-template/generate.yml"
        # /usr/bin/python3 $oqs_build_dir/openssl/oqs-template/generate.py
        # cd "$oqs_build_dir/openssl"
        # make generate_crypto_objects
        # make -j $threads

    fi
    
    cd "$root_dir/build-scripts"

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
                
                echo "Building Liboqs..."
                dependency_install
                liboqs_build_type=0
                liboqs-build
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