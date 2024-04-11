#!/bin/bash

#Copyright (c) 2023 Callum Turino
#SPDX-License-Identifier: MIT

# Server script for the TLS handshake tests, this script will coordinate with the client machine to conduct the tests
# using  all the combinations of PQC sig/kem and ECC Curve/Ciphesuite using the test parameters. This script consists
# of two main tests, the PQC TLS handshake tests and the Classic TLS handshake tests. 

#------------------------------------------------------------------------------
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
provider_path="$libs_dir/oqs-openssl/lib"

# Declaring key storage dir paths
key_storage_path="$test_data_dir/keys"
pqc_cert_dir="$key_storage_path/pqc"
classic_cert_dir="$key_storage_path/classic"
hybrid_cert_dir="$key_storage_path/hybrid"

# Declaring global flags
test_type=0 #0=pqc, 1=classic, 2=hybrid

# Exporting openssl lib path
if [[ -d "$open_ssl_path/lib64" ]]; then
    openssl_lib_path="$open_ssl_path/lib64"
else
    openssl_lib_path="$open_ssl_path/lib"
fi

export LD_LIBRARY_PATH="$openssl_lib_path:$LD_LIBRARY_PATH"

# Define the cipher suites
ciphers=("TLS_AES_256_GCM_SHA384" "TLS_CHACHA20_POLY1305_SHA256" "TLS_AES_128_GCM_SHA256")
ecc_curves=("prime256v1" "secp384r1" "secp521r1")
classic_algs=("RSA:2048" "RSA:3072" "RSA:4096" "prime256v1" "secp384r1" "secp521r1")

# Decalring current group var that will be passed to DEFAULT_GROUP env var when changing test type
current_group=""


#------------------------------------------------------------------------------
function get_algs() {
    # Function for reading in the various algorithms into an array for use within the script

    # Declaring algorithm lists filepaths
    kem_alg_file="$test_data_dir/alg-lists/ssl-kem-algs.txt"
    sig_alg_file="$test_data_dir/alg-lists/ssl-sig-algs.txt"
    hybrid_kem_alg_file="$test_data_dir/alg-lists/ssl-hybr-kem-algs.txt"
    hybrid_kem_alg_file="$test_data_dir/alg-lists/ssl-hybr-sig-algs.txt"

    # Kem algorithms array
    kem_algs=()
    while IFS= read -r line; do
        kem_algs+=("$line")
    done < $kem_alg_file

    # Sig algorithms array
    sig_algs=()
    while IFS= read -r line; do
        sig_algs+=("$line")
    done < $sig_alg_file

    # classic algorithms array
    classic_sigs=( "RSA:2048" "RSA:3072" "RSA:4096" "prime256v1" "secp384r1" "secp521r1")

}

#------------------------------------------------------------------------------
function set_group() {
    # Function for setting the default group depending on what type of tls test is being performed (pqc,classic,hybrid)

    # Clearing current_group array
    current_group=""

    if [ "$test_type" -eq 0 ]; then
        for kem_alg in "${kem_algs[@]}"; do
            current_group+=":$kem_alg"
        done
        current_group="${current_group:1}"

    elif [ "$test_type" -eq 1 ]; then
        for classic_sig in "${kem_algs[@]}"; do
            current_group+=":$classic_sig"
        done

    fi

    # Remove beginning : from start of first algorithm (will find better solution for this)
    current_group="${current_group:1}"

    # Export default group env var for openssl.cnf
    export DEFAULT_GROUPS=$current_group

}

#------------------------------------------------------------------------------
function send_signal() {
    # Function for sending signals to the server that are not part of the control handshake

    # Sending signal to client based on type
    local type="$1"
    if [ $type == "normal" ]; then

        # Send control signal
        until nc -z -v -w 1 $CLIENT_IP 12346 > /dev/null 2>&1; do
            if [ $? -ne 0 ]; then
                :
            else
                break
            fi
        done

    elif [ $type == "ready" ]; then 

        # Send server ready signal
        until echo "ready" | nc -n -w 1 $CLIENT_IP 12346 > /dev/null 2>&1; do
            if [ $? -ne 0 ]; then
                :
            else
                break
            fi
        done

    elif [ $type == "skip" ]; then

        # Send test skip signal
        until echo "skip" | nc -n -w 1 $CLIENT_IP 12346 > /dev/null 2>&1; do
            if [ $? -ne 0 ]; then
                :
            else
                break
            fi
        done
    
    elif [ $type == "iteration_handshake" ]; then

        # Wait for ready connection from client
        while true; do

        # Wait for a connection from the client and capture the request in a variable
        signal_message=$(nc -l -p 12345)
        if [[ $signal_message == "ready" ]]; then
            break
        fi

        done

        # Sending ready message to client
        until echo "ready" | nc -n -w 1 $CLIENT_IP 12346 > /dev/null 2>&1; do
            if [ $? -ne 0 ]; then
                :
            else
                break
            fi
        
        done

    fi

}

#------------------------------------------------------------------------------
function contains() {
    # Function for checking if var is in provided array

    local e match="$1"
    shift

    # Looping through array to see if var value is in array
    for e; do [[ "$e" == "$match" ]] && return 0; done
    return 1
}

#------------------------------------------------------------------------------
function classic_tests {
    # Function for performing the classic TLS handshake tests using the given test parameters

    # Running tests for ecdsa ciphers
    for cipher in "${ciphers[@]}"; do

        for classic_alg in "${classic_algs[@]}"; do

            # Performing current run cipher/curve combination test until passed
            while true; do

                # Check if an old openssl process is still active
                pgrep_output=$(pgrep openssl)

                # Kill old process if active
                if [[ ! -z $pgrep_output ]]; then
                    kill "$pgrep_output"
                fi

                # Outputting current tls test info
                echo -e "\n-------------------------------------------------------------------------"
                echo "[OUTPUT] - Classic Cipher Tests, Run - $run_num, Cipher - $cipher, Sig Alg - $classic_alg"

                # Performing iteration handshake
                send_signal "iteration_handshake"

                # Wait for ready signal
                nc -l -p 12345 > /dev/null

                # Checking if RSA or ECC to determine what parameters s_server needs
                if [[ $classic_alg == "prime256v1" || $classic_alg == "secp384r1" || $classic_alg == "secp521r1" ]]; then

                    # Set cert/key filenames for ECC
                    classic_cert_file="$classic_cert_dir/$classic_alg-srv.crt"
                    classic_key_file="$classic_cert_dir/$classic_alg-srv.key"

                    # Start ECC test server processes
                    "$open_ssl_path/bin/openssl" s_server -cert $classic_cert_file -key $classic_key_file -www -tls1_3 -curves $classic_alg -ciphersuites $cipher -accept 4433 &
                    server_pid=$!

                else

                    # Set cert/key filenames for RSA
                    classic_cert_file="$classic_cert_dir/$classic_alg-srv.crt"
                    classic_key_file="$classic_cert_dir/$classic_alg-srv.key"

                    # Start RSA test server processes
                    "$open_ssl_path/bin/openssl" s_server -cert $classic_cert_file -key $classic_key_file -www -tls1_3 -ciphersuites $cipher -accept 4433 &
                    server_pid=$!

                fi

                # Check if server has started before sending ready signal
                until netstat -tuln | grep ':4433' > /dev/null; do
                    :
                done

                # Wait for server to start and send ready signal to client
                send_signal "normal"

                # Wait for test status signal from client
                signal_message=$(nc -l -p 12345)

                # Check test status signal received from client
                if [ $signal_message == "complete" ]; then

                    # Successful completion of test from client
                    kill $server_pid
                    break

                elif [ $signal_message == "failed" ]; then

                    # Restart sig/kem combination if failed signal from client
                    echo "[ERROR] - 3000 failed attempts signal received from client, restarting sig/kem combination"
                    kill $server_pid
                    sleep 2
                
                fi

            done

        done

    done

}

#------------------------------------------------------------------------------
function pqc_tests() {
    # Function for performing the PQC TLS handshake tests using the given test parameters

    # Looping through all PQC sig algs to be used for signing
    for sig in "${sig_algs[@]}"; do

        # Looping through all PQC KEM algs to be used for key exchange
        for kem in "${kem_algs[@]}"; do

            # Performing current run sig/kem combination test until passed
            while true; do

                # Check if an old openssl process is still active
                pgrep_output=$(pgrep openssl)

                # Kill old process if active
                if [[ ! -z $pgrep_output ]]; then
                    kill "$pgrep_output"
                fi

                # Outputting current tls test info
                echo -e "\n-------------------------------------------------------------------------"
                echo "[OUTPUT] - Run - $run_num, Signature - $sig, KEM - $kem"

                # Performing iteration handshake
                send_signal "iteration_handshake"

                # Wait for ready from client signal
                nc -l -p 12345 > /dev/null

                # if contains "$sig" "${classic_algs[@]}" && contains "$kem" "${classic_algs[@]}"; then

                #     # Sending skip signal to server 
                #     echo "[OUTPUT] - Skipping as Sig and Kem are both classic!!!"
                #     send_signal "skip"

                #     # Wait for done signal from client
                #     nc -l -p 12345 > /dev/null
                #     break

                # else

                # Setting cert and key files
                pqc_cert_file="$pqc_cert_dir/""${sig/:/_}""-srv.crt"
                pqc_key_file="$pqc_cert_dir/""${sig/:/_}""-srv.key"

                # Starting server process
                # "$open_ssl_path/bin/openssl" s_server -cert $pqc_cert_file -key $pqc_key_file -www -tls1_3 -curves $kem &
                # server_pid=$!

                echo "server openssl s_server params"
                echo $pqc_cert_file
                echo $pqc_key_file
                echo $kem
                echo $provider_path
                echo "version:"
                "$open_ssl_path/bin/openssl" version

                "$open_ssl_path/bin/openssl" s_server -cert $pqc_cert_file -key $pqc_key_file -www -tls1_3 -groups $kem \
                    -provider oqsprovider -provider-path $provider_path -accept 4433 &
                server_pid=$!

                # Check if server has started before sending ready signal
                until netstat -tuln | grep ':4433' > /dev/null; do
                    :
                done

                # Send ready signal to client
                send_signal "ready"

                # Check test status signal from client
                signal_message=$(nc -l -p 12345)

                if [ $signal_message == "complete" ]; then

                    # Successful completion of test from client
                    kill $server_pid
                    break

                elif [ $signal_message == "failed" ]; then

                    # Restart sig/kem combination if failed signal from client
                    echo "[ERROR] - 100 failed attempts signal received from client, restarting sig/kem combination"
                    kill $server_pid
                    sleep 2
                
                fi

                #fi

            done

        done
    
    done

}

#------------------------------------------------------------------------------
function main() {
    # Main function which controls the server testing scripts which are called for TLS handshake performance test

    # Import algorithms and clear terminal
    get_algs
    clear

    # Outputting test type message
    echo -e "\n####################################"
    echo "Performing TLS Handshake Speed Tests"
    echo -e "####################################\n"

    # Performing initial handshake with client
    echo -e "Server Script Activated, waiting for connection from client..."
    send_signal "iteration_handshake"

    # Performing tests
    for run_num in $(seq 1 $NUM_RUN); do

        # Performing output test start message
        echo -e "\n-----------------------------"
        echo "Performing TLS Speed Run - $run_num"
        echo -e "\n-----------------------------"

        # Performing run PQC test
        echo -e "[OUTPUT] - PQC run $run_num"
        send_signal "iteration_handshake"

        # Calling PQC Tests
        test_type=0 #0=pqc, 1=classic, 2=hybrid
        set_group
        pqc_tests
        echo -e "[OUTPUT] - Completed $run_num PQC Tests"

        # # # Performing run classic test
        # echo "-----------------"
        # echo "Classic run $run_num"
        # echo -e "-----------------\n"
        # send_signal "iteration_handshake"

        # # Performing current run classic Tests
        # test_type=1 #0=pqc, 1=classic, 2=hybrid
        # set_group
        # classic_tests
        # echo "[OUTPUT] - Completed $run_num Classic Elliptic Tests"

        # Outputting run complete
        echo -e "All $run_num Testing Completed"
    
    done

}
main
