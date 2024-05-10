#!/bin/bash

#Copyright (c) 2023 Callum Turino
#SPDX-License-Identifier: MIT

# Client script for the TLS handshake tests, this script will coordinate with the server machine to conduct the tests
# using  all the combinations of PQC sig/kem and ECC Curve/Ciphesuite using the test parameters. This script consists
# of two main tests, the PQC TLS handshake tests and the Classic TLS handshake tests. 

#------------------------------------------------------------------------------
# Declaring directory path variables
root_dir=$(cd "$PWD"/../.. && pwd)
libs_dir="$root_dir/lib"
tmp_dir="$root_dir/tmp"
test_data_dir="$root_dir/test-data"
test_scripts_path="$root_dir/scripts/test-scripts"
util_scripts="$root_dir/scripts/utility-scripts"

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

# Decalring current group var that will be passed to DEFAULT_GROUP env var when changing test type
current_group=""

# Declaring static algorithm arrays and alg-list filepaths
kem_alg_file="$test_data_dir/alg-lists/ssl-kem-algs.txt"
sig_alg_file="$test_data_dir/alg-lists/ssl-sig-algs.txt"
hybrid_kem_alg_file="$test_data_dir/alg-lists/ssl-hybr-kem-algs.txt"
hybrid_sig_alg_file="$test_data_dir/alg-lists/ssl-hybr-sig-algs.txt"

classic_algs=( "RSA_2048" "RSA_3072" "RSA_4096" "prime256v1" "secp384r1" "secp521r1")
ciphers=("TLS_AES_256_GCM_SHA384" "TLS_CHACHA20_POLY1305_SHA256" "TLS_AES_128_GCM_SHA256")


#------------------------------------------------------------------------------
function set_test_env() {
    # Function for setting the default group depending on what type of tls test is being performed (pqc,classic,hybrid)
    #0=pqc, 1=classic, 2=hybrid

    local test_type="$1"
    local configure_mode="$2"

    # Clearing current_group array
    current_group=""

    if [ "$test_type" -eq 0 ]; then

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

        # Populate current group array with PQC algs
        for kem_alg in "${kem_algs[@]}"; do
            current_group+=":$kem_alg"
        done

        # Remove beginning : at index 0
        current_group="${current_group:1}"

        # Set configurations in openssl.cnf file for PQC testing
        "$util_scripts/configure-openssl-cnf.sh" $configure_mode

    elif [ "$test_type" -eq 1 ]; then # probs not needed and can remove

        # Set configurations in openssl.cnf file for Classic testing
        "$util_scripts/configure-openssl-cnf.sh" $configure_mode

    elif [ "$test_type" -eq 2 ]; then

        # Hybrid kem algorithms array
        kem_algs=()
        while IFS= read -r line; do
            kem_algs+=("$line")
        done < $hybrid_kem_alg_file

        # Hybrid sig algorithms array
        sig_algs=()
        while IFS= read -r line; do
            sig_algs+=("$line")
        done < $hybrid_sig_alg_file

        # Populate current group array with PQC algs
        for hyrb_kem_alg in "${kem_algs[@]}"; do
            current_group+=":$hyrb_kem_alg"
        done

        # Remove beginning : at index 0
        current_group="${current_group:1}"

        # Set configurations in openssl.cnf file for PQC testing
        "$util_scripts/configure-openssl-cnf.sh" $configure_mode

    fi

    # Export default group env var for openssl.cnf
    export DEFAULT_GROUPS=$current_group

}

#------------------------------------------------------------------------------
function control_signal() {
    # Function for sending signals to the server that are not part of the control handshake

    # Sending signal to server based on type
    local type="$1"
    if [ $type == "control" ]; then

        # Send control signal
        until nc -z -v -w 1 $SERVER_IP 12345 > /dev/null 2>&1; do
            exit_status=$?
            if [ $exit_status -ne 0 ]; then
                :
            else
                echo "connection worked"
                break
            fi
        done

    elif [ $type == "complete" ]; then

        # Send test complete signal
        until echo "complete" | nc -n -w 1 $SERVER_IP 12345 > /dev/null 2>&1; do
            exit_status=$?
            if [ $exit_status -ne 0 ]; then
                :
            else
                break
            fi
        done

    elif [ $type == "failed" ]; then

        # Send test failed signal
        until echo "failed" | nc -n -w 1 $SERVER_IP 12345 > /dev/null 2>&1; do
            exit_status=$?
            if [ $exit_status -ne 0 ]; then
                :
            else
                break
            fi
        done

   elif [ $type == "iteration_handshake" ]; then

        # Performing handshake with server machine
        until echo "ready" | nc -n -w 1 $SERVER_IP 12345 > /dev/null 2>&1; do
            exit_status=$?
            if [ $exit_status -ne 0 ]; then
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

   fi

}

#------------------------------------------------------------------------------
function classic_tests() {
    # Function for performing the classic TLS handshake tests using the given test parameters

    # Running tests for ecdsa ciphers
    for cipher in "${ciphers[@]}"; do

        for classic_alg in "${classic_algs[@]}"; do

            # Setting fail flag
            fail_flag=0

            # Performing current run cipher/curve combination test until passed
            while true; do

                # Outputting current tls test info
                echo -e "\n-------------------------------------------------------------------------"
                echo "[OUTPUT] - Classic Cipher Tests, Run - $run_num, Cipher - $cipher, Sig Alg - $classic_alg"

                # Performing iteration handshake
                control_signal "iteration_handshake"

                # Send client ready signal
                control_signal "control"

                # Wait for server ready signal
                nc -l -p 12346 > /dev/null
                echo "[OUTPUT] - Starting test"

                # Setting output filename based on current combination and run
                output_name="tls-handshake-classic-$run_num-$cipher-$classic_alg.txt"
                
                # Setting CA file
                classic_cert_file="$classic_cert_dir/$classic_alg-srv.crt"

                # Resetting fail counter
                fail_counter=0

                # Running test
                while true; do

                    # Running test process
                    "$open_ssl_path/bin/openssl" s_time -connect $SERVER_IP:4433 -CAfile $classic_cert_file -time $TIME_NUM > "$CLASSIC_HANDSHAKE/$output_name"
                    exit_code=$?
                    #-ciphersuites $cipher

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
                    control_signal "complete"
                    break

                else
                    echo "[ERROR] - Failed to establish test connection, restarting current run sig/kem combination"
                    control_signal "failed"
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
                echo -e "\n-------------------------------------------------------------------------"
                echo "[OUTPUT] - Run Number - $run_num, Signature - $sig, KEM - $kem"
                
                # Performing iteration handshake
                control_signal "iteration_handshake"

                # Send client ready signal
                control_signal "control"

                # Wait for server ready signal
                signal_message=$(nc -l -p 12346)

                # Perform test or skip based on control signal from server
                if [ $signal_message == "ready" ]; then

                    # Notifying user of starting test
                    echo "[OUTPUT] - Starting test"

                    #Set cert variable based on current sig
                    sig_name="${sig/:/_}"

                    # Setting cert and key files depending on test type
                    if [ "$test_type" -eq 0 ]; then
                        cert_file="$pqc_cert_dir/""${sig_name}""-CA.crt"
                        handshake_dir=$PQC_HANDSHAKE

                    elif [ "$test_type" -eq 2 ]; then
                        cert_file="$hybrid_cert_dir/""${sig/:/_}""-srv.crt"
                        handshake_dir=$HYBRID_HANDSHAKE
                    fi

                    #cert_file="$pqc_cert_dir/""${sig_name}""-CA.crt"

                    # Setting output filename based on current combination and run
                    output_name="tls-handshake-$run_num-$sig_name-$kem.txt"

                    # Resetting fail counter
                    fail_counter=0

                    # Running test
                    while true; do

                        # Running test process
                        "$open_ssl_path/bin/openssl" s_time -connect $server_ip:4433 -CAfile $cert_file -time $TIME_NUM  -verify 1 \
                            -provider default -provider oqsprovider -provider-path $provider_path > $handshake_dir/$output_name
                        exit_code=$?

                        # Check if test process was successful and retrying if not
                        if [ $exit_code -eq 0 ]; then 
                            fail_flag=0
                            break

                        elif [ $fail_counter -eq 3000 ]; then
                            fail_flag=1
                            echo -e "file path for error - $handshake_dir/$output_name"
                            sleep 10
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
                        control_signal "complete"
                        break

                    else

                        # Send failed signal to server and restart sig/kem combination
                        echo "[ERROR] - Failed to establish test connection, restarting current run sig/kem combination"
                        control_signal "failed"
                        sleep 4
                    
                    fi

                elif [ $signal_message == "skip" ]; then

                    #Skipping if both sig and kem are ecc
                    echo "[OUTPUT] - Skipping test as both sig and kem are classic!!!"

                    # Send skip test acknowledgement to server
                    control_signal "control"
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
    clear

    # Getting server ip

    # Performing initial handshake with server
    echo -e "Client Script Activated, connecting to server...\n"
    control_signal "iteration_handshake"

    # Performing tests
    for run_num in $(seq 1 $NUM_RUN); do

        # Performing output test start message
        echo -e "\n************************************************"
        echo "Performing TLS Handshake Tests Run - $run_num"
        echo -e "************************************************\n"
        
        # Performing current run PQC test 
        echo "-----------------"
        echo "PQC run $run_num"
        echo -e "-----------------\n"
        control_signal "iteration_handshake"
        
        # Calling PQC Tests
        test_type=0 #0=pqc, 1=classic, 2=hybrid
        set_test_env $test_type 1
        pqc_tests
        echo -e "[OUTPUT] - Completed $run_num PQC Tests"

        # Performing run handshake
        echo "-----------------"
        echo "Classic run $run_num"
        echo -e "-----------------\n"
        control_signal "iteration_handshake"

        # Performing current run classic Tests
        test_type=1 #0=pqc, 1=classic, 2=hybrid
        set_test_env $test_type 1
        classic_tests
        echo "[OUTPUT] - Completed $run_num Classic TLS Handshake Tests"

        # Performing run handshake
        echo "-----------------"
        echo "Hybrid-PQC run $run_num"
        echo -e "-----------------\n"
        control_signal "iteration_handshake"

        # Performing current run classic Tests
        test_type=2 #0=pqc, 1=classic, 2=hybrid
        set_test_env $test_type 1
        
        pqc_tests
        echo "[OUTPUT] - Completed $run_num Classic TLS Handshake Tests"

        # Outputting run complete
        echo "[OUTPUT] - All $run_num Testing Completed"
        
    done

}
main