#!/bin/bash

#Copyright (c) 2023 Callum Turino
#SPDX-License-Identifier: MIT

# Script for automating the liboqs memory benchmarking tests using the Valgrind Massif memory profiling tool. The script will run the
# tests using the parameters specified in the liboqs test control script, and the results will be outputted to the up-results directory in the code's root

#------------------------------------------------------------------------------
# Declaring directory path variables
current_dir=$(pwd)
root_dir=$(dirname "$current_dir")
device_name=$(hostname)

#------------------------------------------------------------------------------
function initial_setup() {
  # Function for performing the initial test setup including directory management
  # and loading in testing parameters

  # Initial Setup
  if [ -d "$root_dir/builds/x86-liboqs-linux" ]; then

      # Moving directory and clearing old results
      build_dir="builds/x86-liboqs-linux"
      test_dir="$root_dir/$build_dir/tests"
      cd "$root_dir"/"$build_dir"/mem-results/kem-mem-metrics && sudo rm -f *
      cd "$root_dir"/"$build_dir"/mem-results/sig-mem-metrics && sudo rm -f *
      cd "$root_dir"/"$build_dir"/tests

  elif [ -d "$root_dir/builds/arm-liboqs-linux" ]; then

    # Moving directory and clearing old results
    build_dir="builds/arm-liboqs-linux"
    test_dir="$root_dir/$build_dir/tests"
    cd "$root_dir"/"$build_dir"/mem-results/kem-mem-metrics && sudo rm -f *
    cd "$root_dir"/"$build_dir"/mem-results/sig-mem-metrics && sudo rm -f *
    cd "$root_dir"/"$build_dir"/tests

  fi

  # Getting the  number of runs for the test
  if [ -f "$root_dir/tmp/liboqs_number_of_runs.txt" ]; then

      # Read the run number value from the tmp file
      opt1_file_input=$(<"$root_dir/tmp/liboqs_number_of_runs.txt")

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
function create_test_arrays() {
  # Function for creating the needed variables and arrays for the tests functionality

  # Setting alg list filename based on version flag
  version_number=$(cat "$root_dir/alg-lists/version-flag.txt")

  if [[ "$version_number" -eq "0" ]]; 
  then
    kem_alg_file="$root_dir/alg-lists/kem-algs-v7.txt"
    sig_alg_file="$root_dir/alg-lists/sig-algs-v7.txt"
  else
    kem_alg_file="$root_dir/alg-lists/kem-algs-v8.txt"
    sig_alg_file="$root_dir/alg-lists/sig-algs-v8.txt"
  fi

  # Creating algorithm list arrays
  kem_algs=()
  while IFS= read -r line; do
    kem_algs+=("$line")
  done < $kem_alg_file

  sig_algs=()
  while IFS= read -r line; do
    sig_algs+=("$line")
  done < $sig_alg_file

  # Creating prefix variables
  kem_mem_prefix="$root_dir/$build_dir/mem-results/kem-mem-metrics/kem-mem-metrics"
  sig_mem_prefix="$root_dir/$build_dir/mem-results/sig-mem-metrics/sig-mem-metrics"

  # Creating operation arrays
  op_kem=("Keygen" "Encaps" "Decaps")
  op_sig=("Keygen" "Sign" "Verify")

}

#------------------------------------------------------------------------------
function main() {
  # Main function for performing the memory benchmark testing

  # Performing initial setup
  initial_setup

  # Creating test arrays
  create_test_arrays

  # Outputting test start message
  echo -e "***************************\n"
  echo -e "Performing Memory Tests:-\n"
  echo -e "***************************\n\n"
  run_count=1

  # Performing the memory tests with the specified number of runs
  for run_count in $(seq 1 $number_of_runs); do

      # Outputting current test run
      echo -e "Memory Test Run - $run_count\n\n"
      
      # Outputting starting kem tests
      echo -e "KEM Memory Tests\n"

      # KEM memory tests
      for kem_alg in "${kem_algs[@]}"; do

          # Testing memory metrics for each operation
          for operation_1 in {0..2}; do

              # Getting operation string and outputting to terminal
              op_kem_str=${op_kem[operation_1]}
              echo -e "$kem_alg - $op_kem_str Test\n"

              # Running valgrind and outputting metrics
              valgrind --tool=massif --stacks=yes --massif-out-file=massif.out ./test_kem_mem "$kem_alg" "$operation_1"
              filename="$kem_mem_prefix-$kem_alg-$operation_1-$run_count.txt"
              ms_print massif.out > $filename
              rm -f "$test_dir/massif.out"
              echo -e "\n"

          done

          # Clearing the tmp directory before next test
          cd "$test_dir/tmp" && rm -f ./* && cd $test_dir

      done

      # Outputting starting digital signature tests
      echo -e "\nDigital Signature Memory Tests\n"

      # Digital signature memory tests
      for sig_alg in "${sig_algs[@]}"; do

          # Testing memory metrics for each operation
          for operation_2 in {0..2}; do

            # Getting operation string and outputting to terminal
            op_sig_str=${op_sig[operation_2]}
            echo -e "$sig_alg - $op_sig_str Test\n"

            # Running Valgrind and outputting metrics
            filename="$sig_mem_prefix-$sig_alg-$operation_2-$run_count.txt"
            valgrind --tool=massif --stacks=yes --massif-out-file=massif.out ./test_sig_mem "$sig_alg" "$operation_2"
            ms_print massif.out > $filename
            rm -f "$test_dir/massif.out"
            echo -e "\n"

          done

          # Clearing the tmp directory before the next test
          cd "$test_dir/tmp" && rm -f ./* && cd $test_dir
      
      done

  done

  # Outputting complete message
  echo -e "\nMemory Tests Complete\n"

  # Moving final results
  mv "$root_dir/$build_dir/mem-results/kem-mem-metrics" "$root_dir"/up-results/liboqs/mem-results/
  mv "$root_dir/$build_dir/mem-results/sig-mem-metrics" "$root_dir"/up-results/liboqs/mem-results/
  mkdir -p "$root_dir"/"$build_dir"/mem-results/kem-mem-metrics && mkdir -p "$root_dir"/"$build_dir"/mem-results/sig-mem-metrics
  cd "$root_dir"/test-scripts

}
main 