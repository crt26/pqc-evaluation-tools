#!/bin/bash

# Copyright (c) 2024 Callum Turino
# SPDX-License-Identifier: MIT

# This is a utility script used to configure the openssl.cnf file for the OpenSSL library 
# to allow for the generation of post-quantum cryptographic keys. The script is used to 
# comment out the default groups in the configuration file to allow for the use of the scheme groups included with the OQS-Provider library.

#-------------------------------------------------------------------------------------------------------------------------------
# Declaring directory path variables
root_dir=$(cd "$PWD"/../.. && pwd)
libs_dir="$root_dir/lib"
tmp_dir="$root_dir/tmp"
test_data_dir="$root_dir/test-data"
test_scripts_path="$root_dir/scripts/test-scripts"

# Declaring global library path files
open_ssl_path="$libs_dir/openssl_3.2"
liboqs_path="$libs_dir/liboqs"
oqs_openssl_path="$libs_dir/oqs-openssl"

# Exporting openssl lib path
if [[ -d "$open_ssl_path/lib64" ]]; then
    openssl_lib_path="$open_ssl_path/lib64"
else
    openssl_lib_path="$open_ssl_path/lib"
fi

export LD_LIBRARY_PATH="$openssl_lib_path:$LD_LIBRARY_PATH"

#-------------------------------------------------------------------------------------------------------------------------------
function configure_conf_statements() {
    # Function for commenting out additional lines in the openssl to temporarily remove the default groups configuration
    # used in testing scripts to allow key generation to be performed

    # Declare required local variables
    local conf_path="$open_ssl_path/openssl.cnf"
    local configure_mode="$1"

    # Set the configurations based on the configuration mode passed
    if [ "$configure_mode" -eq 0 ]; then

        # Comment out the unnecessary lines for standard configuration
        sed -i 's/ssl_conf = ssl_sect/#ssl_conf = ssl_sect/' $conf_path
        sed -i 's/system_default = system_default_sect/#system_default = system_default_sect/' $conf_path
        sed -i 's/Groups = \$ENV::DEFAULT_GROUPS/#Groups = \$ENV::DEFAULT_GROUPS/' $conf_path

    elif [ "$configure_mode" -eq 1 ]; then 

        # Uncomment configurations for PQC testing
        sed -i 's/^#ssl_conf = ssl_sect/ssl_conf = ssl_sect/' $conf_path
        sed -i 's/^#system_default = system_default_sect/system_default = system_default_sect/' $conf_path
        sed -i 's/^#Groups = \$ENV::DEFAULT_GROUPS/Groups = \$ENV::DEFAULT_GROUPS/' $conf_path

    fi

}

#-------------------------------------------------------------------------------------------------------------------------------
function main() {
    # Main function for controlling the utility script

    # Check if the correct number of arguments is passed
    if [ "$#" -ne 1 ]; then
        echo -e "\nerror in script, incorrect number of arguments passed to configure-openssl-cnf.sh\n"
        sleep 1
        exit 1
    fi

    # Call configure conf file function and pass mode
    configure_conf_statements "$1"

}
main "$@"