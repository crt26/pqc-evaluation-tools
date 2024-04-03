#!/bin/bash

#Copyright (c) 2023 Callum Turino
#SPDX-License-Identifier: MIT

# Script used to generate all the certs and keys needed for the TLS benchmarking tests, this includes creating the
# CA cert and keys, creating a signing requests for the CA, and then signing the certs and keys for the TLS test.
# The keys must then be copied to the client machine, so that each machine has a copy for the tests. This script will 
# create all the PQC and classic certs and keys needed for the TLS handshake benchmarking tests.

#------------------------------------------------------------------------------
# Declaring directory path variables
current_dir=$(pwd)
root_dir=$(dirname "$current_dir")
device_name=$(hostname)
build_dir="$root_dir/builds/oqs-openssl-build/openssl"

# Declaring certs dirs
pqc_cert_dir="$root_dir/keys/pqc"
classic_cert_dir="$root_dir/keys/classic"

# Declaring algorithm lists filepaths
classic_sig_alg_file="$root_dir/alg-lists/classic-ssl-sig-algs.txt"
sig_alg_file="$root_dir/alg-lists/ssl-sig-algs.txt"
kem_alg_file="$root_dir/alg-lists/ssl-kem-algs.txt"


#------------------------------------------------------------------------------
function get_algs() {
    # Function for reading in the signature algs into an array for use within the script

    # Creating algorithm list arrays
    sig_algs=()
    while IFS= read -r line; do
        sig_algs+=("$line")
    done < $sig_alg_file

}

#------------------------------------------------------------------------------
function pqc_keygen() {
    # Function for generating all of the certs and keys needed for the PQC benchmarking tests

    # Ensuring in correct directory
    cd $build_dir

    # Generate a certificate and key for PQC tests
    for sig in "${sig_algs[@]}"; do

        # Setting sig name variable 
        if [[ $sig == RSA:* ]]; 
        then 
            sig_name="${sig/:/_}"
        else
            sig_name=$sig
        fi

        # Check if the algorithm is RSA or ECDSA
        if [[ $sig == RSA:* ]]; then

            # Creating and signing cert for RSA
            "$build_dir/apps/openssl" req -x509 -new -newkey rsa:${sig#RSA:} -keyout "$pqc_cert_dir/$sig_name-CA.key" -out "$pqc_cert_dir/$sig_name-CA.crt" -nodes -subj "/CN=oqstest CA" -days 365 -config apps/openssl.cnf
            "$build_dir/apps/openssl" req -new -newkey rsa:${sig#RSA:} -keyout "$pqc_cert_dir/$sig_name-srv.key" -out "$pqc_cert_dir/$sig_name-srv.csr" -nodes -subj "/CN=oqstest server" -config apps/openssl.cnf
            "$build_dir/apps/openssl" x509 -req -in "$pqc_cert_dir/$sig_name-srv.csr" -out "$pqc_cert_dir/$sig_name-srv.crt" -CA "$pqc_cert_dir/$sig_name-CA.crt" -CAkey "$pqc_cert_dir/$sig_name-CA.key" -CAcreateserial -days 365

        elif [[ $sig == prime256v1 || $sig == secp384r1 || $sig == secp521r1 ]]; then

            # Creating and signing cert for ECDSA
            "$build_dir/apps/openssl" req -x509 -new -newkey ec:<(apps/openssl ecparam -name $sig) -keyout "$pqc_cert_dir/$sig_name-CA.key" -out "$pqc_cert_dir/$sig_name-CA.crt" -nodes -subj "/CN=oqstest $sig CA" -days 365 -config apps/openssl.cnf
            "$build_dir/apps/openssl" req -new -newkey ec:<(apps/openssl ecparam -name $sig) -keyout "$pqc_cert_dir/$sig_name-srv.key"  -out "$pqc_cert_dir/$sig_name-srv.csr" -nodes -subj "/CN=oqstest  $sig server" -config apps/openssl.cnf
            "$build_dir/apps/openssl" x509 -req -in "$pqc_cert_dir/$sig_name-srv.csr" -out "$pqc_cert_dir/$sig_name-srv.crt" -CA "$pqc_cert_dir/$sig_name-CA.crt" -CAkey "$pqc_cert_dir/$sig_name-CA.key" -CAcreateserial -days 365
        else

            # Creating and signing cert for post-quantum algorithm
            "$build_dir/apps/openssl" req -x509 -new -newkey $sig -keyout "$pqc_cert_dir/$sig_name-CA.key" -out "$pqc_cert_dir/$sig_name-CA.crt" -nodes -subj "/CN=oqstest $sig CA" -days 365 -config apps/openssl.cnf
            "$build_dir/apps/openssl" req -new -newkey $sig -keyout "$pqc_cert_dir/$sig_name-srv.key" -out "$pqc_cert_dir/$sig_name-srv.csr" -nodes -subj "/CN=oqstest $sig server" -config apps/openssl.cnf
            "$build_dir/apps/openssl" x509 -req -in "$pqc_cert_dir/$sig_name-srv.csr" -out "$pqc_cert_dir/$sig_name-srv.crt" -CA "$pqc_cert_dir/$sig_name-CA.crt" -CAkey "$pqc_cert_dir/$sig_name-CA.key" -CAcreateserial -days 365
        
        fi
    
    done
}

#------------------------------------------------------------------------------
function classic_keygen() {
    # Function for generating all of the certs and keys needed for the classic benchmarking tests

    # Ensuring in the correct directory
    cd $build_dir

    # Declaring curves array
    ecc_curves=( "prime256v1" "secp384r1" "secp521r1")

    for curve in "${ecc_curves[@]}"; do
    
        # Generate ECC certs and keys
        "$build_dir/apps/openssl" req -x509 -new -newkey ec:<(apps/openssl ecparam -name $curve) -keyout "$classic_cert_dir/$curve-ecdsa-CA.key" -out "$classic_cert_dir/$curve-ecdsa-CA.crt" -nodes -subj "/CN=oqstest $curve CA" -days 365 -config apps/openssl.cnf
        "$build_dir/apps/openssl" req -new -newkey ec:<(apps/openssl ecparam -name $curve) -keyout "$classic_cert_dir/$curve-ecdsa-srv.key" -out "$classic_cert_dir/$curve-ecdsa-srv.csr" -nodes -subj "/CN=oqstest  $curve server" -config apps/openssl.cnf
        "$build_dir/apps/openssl" x509 -req -in "$classic_cert_dir/$curve-ecdsa-srv.csr" -out "$classic_cert_dir/$curve-ecdsa-srv.crt" -CA "$classic_cert_dir/$curve-ecdsa-CA.crt" -CAkey "$classic_cert_dir/$curve-ecdsa-CA.key" -CAcreateserial -days 365
    
    done

}

#------------------------------------------------------------------------------
function main() {
    # Main function which controls the generation process

    # Get alg lists
    get_algs

    # Removing old keys if present and creating key dirs
    if [ -d "$root_dir/keys/" ]; then
        rm -rf "$root_dir/keys/"
    fi
    mkdir -p $pqc_cert_dir
    mkdir -p $classic_cert_dir
    
    # Ensuring in correct directory
    cd $build_dir

    # Generating certs and keys for PQC tests
    echo "Generating certs and keys for PQC tests:"
    pqc_keygen

    # #Generating certs and keys for classic ciphersuite tests
    echo -e "\nGenerating certs and keys for classic ciphersuite tests:"
    classic_keygen

}
main
