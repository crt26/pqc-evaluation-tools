#!/bin/bash

#Copyright (c) 2023 Callum Turino
#SPDX-License-Identifier: MIT

# Server script for the TLS handshake tests, this script will coordinate with the client machine to conduct the tests
# using  all the combinations of PQC sig/kem and ECC Curve/Ciphesuite using the test parameters. This script consists
# of two main tests, the PQC TLS handshake tests and the Classic TLS handshake tests. 

#------------------------------------------------------------------------------
# Declaring directory path variables
current_dir=$(pwd)
root_dir=$(dirname "$current_dir")
device_name=$(hostname)
keys_dir="$root_dir/keys"
build_dir="$root_dir/builds/oqs-openssl-build/openssl"

# Declaring algorithm lists filepaths
sig_alg_file="$root_dir/alg-lists/ssl-sig-algs.txt"
kem_alg_file="$root_dir/alg-lists/ssl-kem-algs.txt"

# Define the cipher suites
ciphers=("TLS_AES_256_GCM_SHA384" "TLS_CHACHA20_POLY1305_SHA256" "TLS_AES_128_GCM_SHA256")
ecc_curves=("prime256v1" "secp384r1" "secp521r1")
classic_algs=("RSA:2048" "RSA:3072" "RSA:4096" "prime256v1" "secp384r1" "secp521r1")

# Declaring certs dir
pqc_cert_dir="$root_dir/keys/pqc"
classic_cert_dir="$root_dir/keys/classic"

#------------------------------------------------------------------------------
function get_algs() {
    # Function for reading in the various algorithms into an array for use within the script

    # Creating algorithm list arrays

    # Kem algorithms
    kem_algs=()
    while IFS= read -r line; do
        kem_algs+=("$line")
    done < $kem_alg_file

    # Sig algorithms
    sig_algs=()
    while IFS= read -r line; do
        sig_algs+=("$line")
    done < $sig_alg_file

}

#------------------------------------------------------------------------------
function get_test_options() {
    # Function for reading in the test parameters which were specified within the OQS-OpenSSL
    # test control script

    # Getting the specified number of runs and storing value
    if [ -f "$root_dir/tmp/tls_number_of_runs.txt" ]; then

        # Read the run number value from the tmp file
        opt1_file_input=$(<"$root_dir/tmp/tls_number_of_runs.txt")

        # Check if the run number value is a valid
        if [[ $opt1_file_input =~ ^[0-9]+$ ]]; then
            # Store the value as an integer variable
            number_of_runs=$opt1_file_input
        else
            echo "Invalid run number value, please ensure value is correct when starting test"
            exit 1
        fi

    else
        echo "Run number file not found, please ensure run number file is present in repo tmp directory"
        exit 1
    
    fi

}

#------------------------------------------------------------------------------
function send_signal() {
    # Function for sending signals to the server that are not part of the control handshake

    # Sending signal to client based on type
    local type="$1"
    if [ $type == "normal" ]; then

        # Send control signal
        until nc -z -v -w 1 $client_ip 12346 > /dev/null 2>&1; do
            if [ $? -ne 0 ]; then
                :
            else
                break
            fi
        done

    elif [ $type == "ready" ]; then 

        # Send server ready signal
        until echo "ready" | nc -n -w 1 $client_ip 12346 > /dev/null 2>&1; do
            if [ $? -ne 0 ]; then
                :
            else
                break
            fi
        done

    elif [ $type == "skip" ]; then

        # Send test skip signal
        until echo "skip" | nc -n -w 1 $client_ip 12346 > /dev/null 2>&1; do
            if [ $? -ne 0 ]; then
                :
            else
                break
            fi
        done
    
    fi

}

#------------------------------------------------------------------------------
function control_handshake(){
    # Function used for conducting the control handshakes with the client machine

    # Wait for ready connection from client
    while true; do

        # Wait for a connection from the client and capture the request in a variable
        signal_message=$(nc -l -p 12345)

        if [[ $signal_message == "ready" ]]; then
            break
        fi

    done

    # Sending ready message to client
    until echo "ready" | nc -n -w 1 $client_ip 12346 > /dev/null 2>&1; do
        if [ $? -ne 0 ]; then
            :
        else
            break
        fi
    
    done

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

        for curve in "${ecc_curves[@]}"; do

            # Performing current run cipher/curve combination test until passed
            while true; do

                # Check if an old openssl process is still active
                pgrep_output=$(pgrep openssl)

                # Kill old process if active
                if [[ ! -z $pgrep_output ]]; then
                    kill "$pgrep_output"
                fi

                # Outputting current tls test info
                echo -e "\n************************************************"
                echo "[OUTPUT] - ECC Cipher Tests, Run - $run_num, Cipher - $cipher, Curve - $curve"

                # Performing iteration handshake
                control_handshake

                # Wait for ready signal
                nc -l -p 12345 > /dev/null

                # Setting needed .pem file
                classic_cert_file="$classic_cert_dir/$curve-ecdsa-srv.crt"
                classic_key_file="$classic_cert_dir/$curve-ecdsa-srv.key"

                # Start test server processes
                "$build_dir/apps/openssl" s_server -cert $classic_cert_file -key $classic_key_file -www -tls1_3 -curves $curve -ciphersuites $cipher &
                server_pid=$!
 
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
                echo -e "\n************************************************"
                echo "[OUTPUT] - Run - $run_num, Signature - $sig, KEM - $kem"

                # Performing iteration handshake
                control_handshake

                # Wait for ready from client signal
                nc -l -p 12345 > /dev/null

                if contains "$sig" "${classic_algs[@]}" && contains "$kem" "${classic_algs[@]}"; then

                    # Sending skip signal to server 
                    echo "[OUTPUT] - Skipping as Sig and Kem are both classic!!!"
                    send_signal "skip"

                    # Wait for done signal from client
                    nc -l -p 12345 > /dev/null
                    break

                else

                    # Setting cert and key files
                    pqc_cert_file="$pqc_cert_dir/""${sig/:/_}""-srv.crt"
                    pqc_key_file="$pqc_cert_dir/""${sig/:/_}""-srv.key"

                    # Starting server process
                    "$build_dir/apps/openssl" s_server -cert $pqc_cert_file -key $pqc_key_file -www -tls1_3 -curves $kem &
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

                fi

            done

        done
    
    done

}

#------------------------------------------------------------------------------
function main() {
    # Main function which controls the server testing scripts which are called for TLS
    # handshake performance test

    # Import test parameters and clear terminal
    get_algs
    get_test_options
    clear

    # Getting server ip
    client_ip=$(cat "$root_dir/tmp/client-ip.txt")

    # Performing initial handshake with client
    echo -e "Server Script Activated, waiting for connection from client..."
    control_handshake

    # Performing tests
    for run_num in $(seq 1 $number_of_runs); do

        # Performing output test start message
        echo -e "\n************************************************"
        echo "[OUTPUT] - Performing TLS Speed Run - $run_num"
        echo -e "\n************************************************"

        # Performing run PQC test
        echo -e "[OUTPUT] - PQC run $run_num"
        control_handshake

        # Calling PQC Tests
        pqc_tests
        echo -e "[OUTPUT] - Completed $run_num PQC Tests"

        # Performing run classic test
        echo -e "\n************************************************"
        echo "[OUTPUT] - Classic Run $run_num"
        echo "[HANDSHAKE] - Performing Classic Run Handshake"
        control_handshake

        # Classic Tests
        classic_tests
        echo "[OUTPUT] - Completed $run_num Classic Elliptic Tests"

        # Outputting run complete
        echo -e "All $run_num Testing Completed"
    
    done

}
main
