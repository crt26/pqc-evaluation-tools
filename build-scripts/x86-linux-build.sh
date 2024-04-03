#!/bin/bash

#Copyright (c) 2023 Callum Turino
#SPDX-License-Identifier: MIT

# Script for building and compiling the OQS-OpenSSL Liboqs library for x86 linux based systems

#------------------------------------------------------------------------------
# Directory path variables
current_dir=$(pwd)
script_root_dir=$(dirname "$(pwd)")
scripts_dir="$script_root_dir/build-scripts"
build_dir="x86-liboqs-linux"

#------------------------------------------------------------------------------
function dependency_install() {
    # Function for checking if there any missing dependencies required for the testing

    # Check for and install required packages
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
        sudo apt-get install -y "${not_installed[@]}" 
    fi
    
}

#------------------------------------------------------------------------------
function main() {
    # Main funciton, handles the buidling process for x86 Linux 

    # Ensuring all dependencies have been installed
    dependency_install

    # Setting up build directory and building liboqs
    cd "$script_root_dir/liboqs/" && mkdir "$build_dir" && cd "$build_dir"
    cmake -GNinja .. -DCMAKE_INSTALL_PREFIX=./ && ninja -j 6 && ninja install
    mkdir -p mem-results/kem-mem-metrics/ && mkdir -p mem-results/sig-mem-metrics/ && mkdir speed-results

    # Making directory for this build and moving
    cd .. 
    mv "$build_dir" "$script_root_dir/builds/"
    cd "$script_root_dir"/build-scripts
    
}
main