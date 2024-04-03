#!/bin/bash

#Copyright (c) 2023 Callum Turino
#SPDX-License-Identifier: MIT

# Script for building and compiling the OQS-OpenSSL Liboqs library for ARM based systems

#------------------------------------------------------------------------------
# Declaring directory path variables
current_dir=$(pwd)
script_root_dir=$(dirname "$(pwd)")
scripts_dir="$script_root_dir/build-scripts"
build_dir="arm-liboqs-linux"

#------------------------------------------------------------------------------
function dependency_install() {
    # Function for checking if there any missing dependencies required for the testing

    # Check for missing required packages
    packages=(astyle cmake gcc ninja-build libssl-dev python3-pytest python3-pytest-xdist unzip xsltproc doxygen graphviz python3-yaml valgrind python3-pip libpthread-stubs0-dev)
    not_installed=()
    for package in "${packages[@]}"; do
        if ! dpkg -s "$package" >/dev/null 2>&1; then
            not_installed+=("$package")
        fi
    done

    # Installing any missing dependencies
    if [[ ${#not_installed[@]} -ne 0 ]]; then
        sudo apt-get update
        sudo apt-get install "${not_installed[@]}"
    fi

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
    cd "$script_root_dir/dependency-libs/"
    git clone --branch main https://github.com/mupq/pqax.git
    cd "$script_root_dir"/dependency-libs/pqax/enable_ccr
    make && make install

}

#------------------------------------------------------------------------------
function main() {
    # Main funciton, handles the buidling process for ARM

    # Performing dependency checks
    dependency_install

    # Enabling Pi ARM_PMU if needed
    if grep -q "Raspberry Pi" /proc/device-tree/model; then

        if lsmod | grep -q 'enable_ccr'; then
            echo "The enable_ccr module enabled, skipping build."
        else
            enable_pmu
        fi  
    fi

    # Setting up directory and building liboqs
    cd "$script_root_dir"/liboqs/ && mkdir "$build_dir" && cd "$build_dir"
    cmake -DCMAKE_C_FLAGS="-D_OQS_RASPBERRY_PI -DSPEED_USE_ARM_PMU" -GNinja ..
    ninja -j 4 && sudo ninja install
    mkdir -p mem-results/kem-mem-metrics/ && mkdir -p mem-results/sig-mem-metrics/ && mkdir speed-results

    # Making directory for this build and moving
    cd .. 
    mv "$script_root_dir"/liboqs/"$build_dir" "$script_root_dir"/builds/
    cd "$script_root_dir/build-scripts"
}
main