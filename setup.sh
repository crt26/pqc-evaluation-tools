#!/bin/bash

#Copyright (c) 2023 Callum Turino
#SPDX-License-Identifier: MIT

# Setup script for the automated PQC benchmark testing tools, the script provides various setup options
# depending on the need of the user. The script will generate the needed directories and also install the 
# required dependency packages based on the system the tools are being setup on.

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

# Declaring global source-code paht files
liboqs_source="$tmp_dir/liboqs-source"
oqs_openssl_source="$tmp_dir/oqs-openssl-source"
openssl_source="$tmp_dir/openssl-3.2.1"

# Setting Global flag variables
#use_system_openssl=0
install_type=0 # 0=liboqs-only, 1=liboqs+oqs-openssl, 2=oqs-openssl-only

#------------------------------------------------------------------------------
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
        esac

    done

}

#------------------------------------------------------------------------------
function configure_dirs() {
    # Function for creating the required directories for the automated tools alongside setting the root directory path tmp file

    # Declaring directory check array
    required_dirs=("$libs_dir" "$dependency_dir" "$oqs_source_dir" "$tmp_dir")

    # Check if libs have already been installed based on install type
    case $install_type in
        0)
            if [ -d "$liboqs_path" ]; then
                get_reinstall_choice
            fi
            ;;

        1)
            if [ -d "$liboqs_path" ] || [ -d "$oqs_openssl_path" ]; then
                get_reinstall_choice
            fi
            ;;

        2)
            if [ -d "$oqs_openssl_path" ]; then
                get_reinstall_choice
            fi
            ;;
    esac

    # Removing old dirs depending on install type
    for dir in "${required_dirs[@]}"; do
        echo $dir
        # Check if dir exists and removes for clean install
        if [ -d "$dir" ]; then
            
            # If liboqs is installed and user chooses install type 2, remove only oqs-openssl lib dir and not liboqs_dir
            if [ "$dir" == "$libs_dir" ] && [ "$install_type" -eq 2 ]; then
                rm -rf "$oqs_openssl_path"
                mkdir -p "$oqs_openssl_path"

            elif [ "$dir" == "$tmp_dir" ] && [ "$install_type" -eq 2 ]; then 
                rm -rf "$oqs_openssl_path"

            else
                rm -rf "$dir"
                mkdir -p "$dir"
            fi

        else
            rm -rf "$dir"
            mkdir -p "$dir"
        fi

    done

}

#------------------------------------------------------------------------------
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

    echo "Dependency checks complete"

}

#------------------------------------------------------------------------------
function openssl_build() {

    # Setting thread count for build
    threads=$(nproc)

    "Groups = \"\$ENV::DEFAULT_GROUPS\""

    # Declaring conf file changes array
    oqsprovider_path="$oqs_openssl_path/lib/oqsprovider.so"
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
        "module = $oqs_openssl_path/lib/oqsprovider.so"
        "[ssl_sect]"
        "system_default = system_default_sect"
        "[system_default_sect]"
        "Groups = \$ENV::DEFAULT_GROUPS"
    )

    #     conf_changes=(
    #     "[openssl_init]"
    #     "providers = provider_sect"
    #     "[provider_sect]"
    #     "default = default_sect"
    #     "oqsprovider = oqsprovider_sect"
    #     "[default_sect]"
    #     "activate = 1"
    #     "[oqsprovider_sect]"
    #     "activate = 1"
    #     "module = $oqsprovider_path"
    # )

    # Checking for correct verison of OpenSSL and if missing installing
    installed_version=$(openssl version | awk '{print $2}')
    minimum_version="3.2.0"

    # Compare the versions and instal if required
    if [[ "$(printf '%s\n' "$installed_version" "$minimum_version" | sort -V | head -n1)" = "$minimum_version" ]]; then
        # If the installed version is greater than or equal to the minimum version
        use_system_openssl=1
        open_ssl_path="/usr/bin/openssl"

    else

        use_system_openssl=0

        if [ ! -d "$open_ssl_path" ]; then

            # Getting reuquired version of openssl and extracting
            echo -e "\n######################################"
            echo "Downloading and Building OpenSSL-3.2.1"
            echo -e "######################################\n"
            wget -O "$tmp_dir/openssl-3.2.1.tar.gz" https://www.openssl.org/source/openssl-3.2.1.tar.gz
            tar -xf "$tmp_dir/openssl-3.2.1.tar.gz" -C $tmp_dir
            rm "$tmp_dir/openssl-3.2.1.tar.gz"

            # Building required version of OpenSSL in testing repo only
            echo "Building OpenSSL Library"
            cd $openssl_source
            ./config --prefix="$open_ssl_path" --openssldir="$open_ssl_path" shared >/dev/null
            make -j $threads >/dev/null
            make -j $threads install >/dev/null
            cd $root_dir
            echo -e "OpenSSL build complete"

            # Check lib dir name before exporting temp path 
            if [[ -d "$open_ssl_path/lib64" ]]; then
                openssl_lib_path="$open_ssl_path/lib64"
            else
                openssl_lib_path="$open_ssl_path/lib"
            fi

            # Exporting openssl lib path for check
            export LD_LIBRARY_PATH="$openssl_lib_path:$LD_LIBRARY_PATH"

            # Testing if version has correclty installed
            test_output=$("$open_ssl_path/bin/openssl" version)

            if [[ "$test_output" != "OpenSSL 3.2.1 30 Jan 2024 (Library: OpenSSL 3.2.1 30 Jan 2024)" ]]; then
                echo -e "\n\n!!!Error installing openssl, please verify install process"
                exit 1
            fi

            # Modify conf file to include oqs-openssl as a provider
            cd $open_ssl_path && rm -f openssl.conf && cp "$root_dir/modded-lib-files/openssl.cnf" "$open_ssl_path/"

            for conf_change in "${conf_changes[@]}"; do
                echo $conf_change >> "$open_ssl_path/openssl.cnf"
            done

        else
            echo "openssl build present, skipping build"
        fi

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
    cd $libs_dir
    git clone --branch main https://github.com/mupq/pqax.git
    cd "$libs_dir/pqax/enable_ccr" && make && make install
    cd $root_dir

}

#------------------------------------------------------------------------------
function liboqs-build() {
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

        # Cloning liboqs library repos
        git clone https://github.com/open-quantum-safe/liboqs.git $liboqs_source

        # Setting build options based on current system
        if [ "$(uname -m)" = "x86_64" ] && [ "$(uname -s)" = "Linux" ]; then 
            # x86 linux build options
            build_options="no-shared linux-x86_64"
            build_flags=""
            threads=$(nproc)

        elif [[ "$(uname -m)" = arm* || "$(uname -m)" == aarch* ]]; then

            #ARM arrch64 build options for pi
            build_options="no-shared linux-aarch64"
            build_flags="-DOQS_SPEED_USE_ARM_PMU=ON"
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

        # Replacing test_mem files with modded version
        cp "$root_dir/modded-lib-files/test_sig_mem.c" "$liboqs_source/tests/test_sig_mem.c"
        cp "$root_dir/modded-lib-files/test_kem_mem.c" "$liboqs_source/tests/test_kem_mem.c"

        # # Setting up build directory and building liboqs
        cmake -GNinja -DCMAKE_C_FLAGS="$build_flags" -S "$liboqs_source/" -B "$liboqs_path/build" -DCMAKE_INSTALL_PREFIX="$liboqs_path" \
            -DOQS_USE_OPENSSL=ON -DOPENSSL_ROOT_DIR="$open_ssl_path"

        cmake --build "$liboqs_path/build" -- -j $threads
        cmake --build "$liboqs_path/build" --target install -- -j $threads

        # # Setting up build directory and configuring liboqs
        # cmake -GNinja  -S "$liboqs_source/" -B "$liboqs_path/build" -DCMAKE_INSTALL_PREFIX="$liboqs_path" \
        #     -DCMAKE_C_FLAGS="$build_flags"-DOQS_USE_OPENSSL=ON -DOPENSSL_ROOT_DIR="$open_ssl_path"
        
        # ninja -C "$liboqs_path/build" -j $threads && ninja -C "$liboqs_path/build" install -j $threads

        # Making test data store dirs
        mkdir -p "$liboqs_path/mem-results/kem-mem-metrics/" && mkdir -p "$liboqs_path/mem-results/sig-mem-metrics/" && mkdir "$liboqs_path/speed-results"

        echo "Liboqs Install Complete"

    fi

}

#------------------------------------------------------------------------------
function oqs-openssl-build() {
    # Function for building OQS-OpenSSL library, will build relevant version based on system architecture

    # Cloning needed repos
    echo -e "\n#######################################"
    echo "Downloading and Installing OQS-Provider"
    echo -e "#######################################\n"
    git clone https://github.com/open-quantum-safe/oqs-provider.git $oqs_openssl_source >> /dev/null

    # Enabling disabled signature algorithms before building
    export LIBOQS_SRC_DIR="$liboqs_source"
    cp "$root_dir/modded-lib-files/generate.yml" "$oqs_openssl_source/oqs-template/generate.yml"
    cd $oqs_openssl_source
    /usr/bin/python3 $oqs_openssl_source/oqs-template/generate.py
    cd $root_dir

    # Building OQS-Provider library
    cmake -S $oqs_openssl_source -B "$oqs_openssl_path" -DOPENSSL_ROOT_DIR="$open_ssl_path" -Dliboqs_DIR="$liboqs_path/lib/cmake/liboqs"
    cmake --build "$oqs_openssl_path" -- -j $(nproc)
    cmake --install "$oqs_openssl_path"

    echo "OQS-Provider Install Complete"

}

#------------------------------------------------------------------------------
function main() {
    # Function for  building the specified test suite

    # Loop for setup option selection
    while true; do

        # Outputting options to user and getting input
        echo -e "\nPlease Select one of the following build options"
        echo "1 - Build Liboqs Library Only"
        echo "2 - Build OQS-OpenSSL and Liboqs Library"
        echo "3 - Build OQS-OpenSSL Library with previous Liboqs Install"
        echo "4 - Exit Setup"
        read -p "Enter your choice (1-4): " user_opt

        # Determining action from user input
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
                liboqs-build
                rm -rf $tmp_dir/*

                # Setting root_dir path for scripts
                echo "$root_dir" > "$test_data_dir/root_path.txt"

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
                liboqs-build
                oqs-openssl-build
                rm -rf $tmp_dir/*

                # Setting root_dir path for scripts
                echo "$root_dir" > "$test_data_dir/root_path.txt"

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

                # Building OpenSSL
                openssl_build

                # Check if liboqs is present and install if not
                if [ ! -d "$liboqs_path" ]; then
                    echo -e "\n!!!Liboqs not installed, will install now!!!"
                    install_type=1
                    liboqs-build
                fi

                # Recloning liboqs repo for alg docs if missing as needed for enabling disabled algs in oqs-openssl-build
                if [ ! -d "$liboqs_source" ]; then
                    git clone https://github.com/open-quantum-safe/liboqs.git $liboqs_source >/dev/null
                fi

                # Building oqs-provider
                oqs-openssl-build
                rm -rf $tmp_dir/*

                # Setting root_dir path for scripts
                echo "$root_dir" > "$test_data_dir/root_path.txt"
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

    # Outputting setup complete message
    echo -e "\n\nSetup complete, completed builds can be found in the builds directory"

}
main