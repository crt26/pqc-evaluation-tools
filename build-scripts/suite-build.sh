#!/bin/bash

#Copyright (c) 2023 Callum Turino
#SPDX-License-Identifier: MIT

# Script for controlling the building process of the testing suites, the script will call the relevant building scripts based on
# the flags supplied to it. The script handles the building and compiling the of the OQS Liboqs and OQS-OpenSSL Libraries.

#------------------------------------------------------------------------------
# Getting Global Dir Variables
current_dir=$(pwd)
root_dir=$current_dir
scripts_dir="$root_dir/build-scripts"
build_type_flag=0

#------------------------------------------------------------------------------
function mod-liboqs() {
    # Function for modyfying the liboqs source code to use modifed memory files before building

    # Getting the specified version of liboqs
    cd $root_dir
    version_flag=$(cat "$root_dir/alg-lists/version-flag.txt")

    if [[ "$version_flag" -eq "0" ]]; then
        # fetch a specific commit of liboqs
        git clone https://github.com/open-quantum-safe/liboqs.git
        cd "$root_dir/liboqs"
        git checkout 341cf22427
        cd $root_dir
    
    else
        # fetch the latest version of liboqs
        git clone --branch main https://github.com/open-quantum-safe/liboqs.git
    fi

    # Replacing memory files with modified version
    cp "$root_dir/modded-liboqs-files/test_kem_mem.c" "$root_dir/liboqs/tests/test_kem_mem.c"
    cp "$root_dir/modded-liboqs-files/test_sig_mem.c" "$root_dir/liboqs/tests/test_sig_mem.c"

    cd $root_dir/build-scripts

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
    cd "$root_dir/dependency-libs/"
    git clone --branch main https://github.com/mupq/pqax.git
    cd "$root_dir"/dependency-libs/pqax/enable_ccr
    make && make install

}

#------------------------------------------------------------------------------
function liboqs-build() {
    # Function for building OQS Liboqs library, will build relevant version based on system architecture

    # Removing old liboqs files
    if [ -d "$root_dir/liboqs" ]; then 
        sudo rm -r "$root_dir/liboqs"
    fi

    # Setting build dir
    # Calling liboqs mod function
    mod-liboqs

    # Checking if the liboqs build directories already exist
    if [ -d "$root_dir/builds/x86-liboqs-linux" ] || [ -d "$root_dir/builds/arm-liboqs-linux" ]; then
        echo -e "There is a current build available - skipping build\n"
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

        else
            # Unsupported system error 
            echo -e "Unsupported System Detected - Manual Build Required!\n"
            exit 1
        fi

        # Setting up build directory and building liboqs
        cd "$script_root_dir/liboqs/" && mkdir "$build_dir" && cd "$build_dir"
        cmake -GNinja .. -DCMAKE_INSTALL_PREFIX=./ && ninja -j 6 && ninja install
        mkdir -p mem-results/kem-mem-metrics/ && mkdir -p mem-results/sig-mem-metrics/ && mkdir speed-results

        # Making directory for this build and moving
        cd .. 
        mv "$build_dir" "$script_root_dir/builds/"
        cd "$script_root_dir"/build-scripts

    fi

    cd "$root_dir/build-scripts"

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
    # Main function which handles the suite build based the specified flags

    # Check if no argument or more than one argument is provided
    if [ $# -ne 1 ]; then
        echo "Invalid number of arguments. Please provide exactly one argument: -a, -l or -o."
        exit 1
    fi

    # Perform build process based on provided flag
    while getopts 'alo' OPTION; do
        case "$OPTION" in
            a)

                liboqs-build
                oqs-openssl-build
                ;;
            l)
                liboqs-build
                ;;
            o)
                oqs-openssl-build
                ;;
            *)
                echo "Invalid option. Usage: $(basename $0) [-a] [-l] [-o]"
                exit 1
                ;;
        esac
    done

    # Check if no valid option is provided
    if [ $OPTIND -eq 1 ]; then
        echo "No option provided. Usage: $(basename $0) [-a] [-l] [-o]"
        exit 1
    fi

}
main "$@"
