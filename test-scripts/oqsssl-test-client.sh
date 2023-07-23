#!/bin/bash

#Copyright (c) 2023 Callum Turino
#SPDX-License-Identifier: MIT

# Client script for the TLS handshake tests, this script will coordinate with the server machine to conduct the tests
# using  all the combinations of PQC sig/kem and ECC Curve/Ciphesuite using the test parameters. This script consists
# of two main tests, the PQC TLS handshake tests and the Classic TLS handshake tests. 

#------------------------------------------------------------------------------
# Declaring directory path variables
current_dir=$(pwd)
root_dir=$(dirname "$current_dir")
device_name=$(hostname)
build_dir="$root_dir/builds/oqs-openssl-build/openssl"

# Declaring algorithm lists filepaths
sig_alg_file="$root_dir/alg-lists/ssl-sig-algs.txt"
kem_alg_file="$root_dir/alg-lists/ssl-kem-algs.txt"

# Define the cipher suites
ciphers=("TLS_AES_256_GCM_SHA384" "TLS_CHACHA20_POLY1305_SHA256" "TLS_AES_128_GCM_SHA256")
ecc_curves=("prime256v1" "secp384r1" "secp521r1")

# Declaring pqc dirs
pqc_cert_dir="$root_dir/keys/pqc"
pqc_output_dir="$root_dir/up-results/openssl/pqc-tests"
classic_cert_dir="$root_dir/keys/classic"
classic_output_dir="$root_dir/up-results/openssl/classic-tests"

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

    # Getting the specified length of tls test
    if [ -f "$root_dir/tmp/tls_test_length.txt" ]; then

        # Read the run number value from the tmp file
        opt2_file_input=$(<"$root_dir/tmp/tls_test_length.txt")

        # Check if the run number value is a valid
        if [[ $opt2_file_input =~ ^[0-9]+$ ]]; then
            # Store the value as an integer variable
            test_length=$opt2_file_input
        else
            echo "Invalid TLS test length, please ensure value is correct when starting test"
            exit 1
        fi

    else
        echo "TLS test length file not found, please ensure run number file is present in repo tmp directory"
        exit 1
    
    fi

}

#------------------------------------------------------------------------------
function send_signal() {
    # Function for sending signals to the server that are not part of the control handshake

    # Sending signal to server based on type
    local type="$1"
    if [ $type == "control" ]; then

        # Send control signal
        until nc -z -v -w 1 $server_ip 12345 > /dev/null 2>&1; do
            if [ $? -ne 0 ]; then
                :
            else
                break
            fi
        done

    elif [ $type == "complete" ]; then

        # Send test complete signal
        until echo "complete" | nc -n -w 1 $server_ip 12345 > /dev/null 2>&1; do
            if [ $? -ne 0 ]; then
                :
            else
                break
            fi
        done

    elif [ $type == "failed" ]; then

        # Send test failed signal
        until echo "failed" | nc -n -w 1 $server_ip 12345 > /dev/null 2>&1; do
            if [ $? -ne 0 ]; then
                :
            else
                break
            fi
        done

    fi
}

#------------------------------------------------------------------------------
function control_handshake() {
    # Function used for conducting the control handshakes with the server machine

    # Performing handshake with server machine
    until echo "ready" | nc -n -w 1 $server_ip 12345 > /dev/null 2>&1; do
        if [ $? -ne 0 ]; then
            :
        else
            break
        fi
    
    done

    # Waiting for ready signal from server
    while true; do

        # Wait for a connection from the server and capture the request in a variable
        signal_message=$(nc -l -p 12346)

        if [[ $signal_message == "ready" ]]; then
            break
        fi
    
    done
}

#------------------------------------------------------------------------------
function classic_tests() {
    # Function for performing the classic TLS handshake tests using the given test parameters

    # Running tests for ecdsa ciphers
    for cipher in "${ciphers[@]}"; do

        for curve in "${ecc_curves[@]}"; do

            # Setting fail flag
            fail_flag=0

            # Performing current run cipher/curve combination test until passed
            while true; do

                # Outputting current PQC tls test info
                echo -e "\n************************************************"
                echo "[OUTPUT] - ECC Cipher Tests, Run - $run_num, Cipher - $cipher, Curve - $curve"

                # Performing iteration handshake
                control_handshake
                
                # Send client ready signal
                send_signal "control"

                # Wait for server ready signal
                nc -l -p 12346 > /dev/null
                echo "[OUTPUT] - Starting test"

                # Setting output filename based on current combination and run
                output_name="tls-speed-classic-$run_num-$cipher-$curve.txt"
                
                # Setting CA file
                classic_cert_file="$classic_cert_dir/""$curve-ecdsa-CA.crt"

                # Resetting fail counter
                fail_counter=0

                # Running test
                while true; do

                    # Running test process
                    "$build_dir/apps/openssl" s_time -connect $server_ip:4433 -CAfile $classic_cert_file -time $test_length  -ciphersuites $cipher > "$classic_output_dir/$output_name"
                    exit_code=$?

                    # Check if test was successful and retrying if not
                    if [ $exit_code -eq 0 ]; then
                        fail_flag=0
                        break

                    elif [ $fail_counter -eq 3000 ]; then
                        fail_flag=1
                        break
                    
                    else
                        # Adding to fail counter
                        ((fail_counter++))
                        echo "[ERROR] - s-time process failed $fail_counter times, retrying"
                    
                    fi
                    
                done

                # Sending test complete or failed signal to server
                if [ $fail_flag -eq 0 ]; then

                    # Send complete signal to server
                    send_signal "complete"
                    break

                else
                    echo "[ERROR] - Failed to establish test connection, restarting current run sig/kem combination"
                    send_signal "failed"
                    sleep 4
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

            # Setting fail flag to false
            fail_flag=0

            # Performing current run sig/kem combination test until passed
            while true; do

                # Outputting current tls test info
                echo -e "\n************************************************"
                echo "[OUTPUT] - Run Number - $run_num, Signature - $sig, KEM - $kem"
                
                # Performing iteration handshake
                control_handshake

                # Send client ready signal
                send_signal "control"

                # Wait for server ready signal
                signal_message=$(nc -l -p 12346)

                # Perform test or skip based on control signal from server
                if [ $signal_message == "ready" ]; then

                    # Notifying user of starting test
                    echo "[OUTPUT] - Starting test"

                    #Set cert variable based on current sig
                    sig_name="${sig/:/_}"
                    pqc_cert_file="$pqc_cert_dir/""${sig_name}""-CA.crt"

                    # Setting output filename based on current combination and run
                    output_name="tls-speed-$run_num-$sig_name-$kem.txt"

                    # Resetting fail counter
                    fail_counter=0

                    # Running test
                    while true; do

                        # Running test process
                        "$build_dir/apps/openssl" s_time -connect $server_ip:4433 -CAfile $pqc_cert_file -time $test_length -curves $kem -verify 1 > "$pqc_output_dir/$output_name"
                        exit_code=$?

                        # Check if test process was successful and retrying if not
                        if [ $exit_code -eq 0 ]; then 
                            fail_flag=0
                            break

                        elif [ $fail_counter -eq 3000 ]; then
                            fail_flag=1
                            break

                        else
                            # Adding to fail counter
                            ((fail_counter++))
                            echo "[ERROR] - s-time process failed $fail_counter times, retrying"
                        
                        fi
                        
                    done

                    # Sending test complete or failed signal to server
                    if [ $fail_flag -eq 0 ]; then

                        # Send complete signal to server
                        send_signal "complete"
                        break

                    else

                        # Send failed signal to server and restart sig/kem combination
                        echo "[ERROR] - Failed to establish test connection, restarting current run sig/kem combination"
                        send_signal "failed"
                        sleep 4
                    
                    fi

                elif [ $signal_message == "skip" ]; then

                    #Skipping if both sig and kem are ecc
                    echo "[OUTPUT] - Skipping test as both sig and kem are classic!!!"

                    # Send skip test acknowledgement to server
                    send_signal "control"
                    break
                
                fi
            
            done

        done

    done
}

#------------------------------------------------------------------------------
function main() {
    # Main function which controls the client testing scripts which are called for TLS
    # handshake performance test

    # Import test parameters and clear terminal
    get_algs
    get_test_options
    clear

    # Creating output dirs and removing old if needed
    if [ -d $pqc_output_dir ]; then
        rm -rf $pqc_output_dir
    fi
    mkdir -p $pqc_output_dir

    if [ -d $classic_output_dir ]; then
        rm -rf $classic_output_dir
    fi
    mkdir -p $classic_output_dir

    # Getting server ip
    server_ip=$(cat "$root_dir/tmp/server-ip.txt")

    # Performing initial handshake with server
    echo -e "Client Script Activated, connecting to server...\n"
    control_handshake

    # Performing tests
    for run_num in $(seq 1 $number_of_runs); do

        # Performing output test start message
        echo -e "\n************************************************"
        echo "[OUTPUT] - Performing TLS Speed Run - $run_num"
        echo -e "\n************************************************"
        
        # Performing current run PQC test 
        echo "[OUTPUT] - PQC run $run_num"
        control_handshake
        
        # Calling PQC Tests
        pqc_tests
        echo "[OUTPUT] - Completed $run_num PQC Tests"

        # Performing run handshake
        echo -e "\n************************************************"
        echo "[OUTPUT] - Classic Run $run_num"
        control_handshake

        # Performing current run classic Tests
        classic_tests
        echo "[OUTPUT] - Completed $run_num Classic Elliptic Tests"

        # Outputting run complete
        echo "[OUTPUT] - All $run_num Testing Completed"
        
    done

}
main