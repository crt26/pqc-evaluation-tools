"""
Copyright (c) 2023 Callum Turino
SPDX-License-Identifier: MIT

This python script will parse the liboqs result files outputted by the bash scripts
into csv files. Alongside, calling an average generator script to calculate averages
for the results.

"""

#------------------------------------------------------------------------------
import pandas as pd
import re
import os
import shutil
import sys
import subprocess
from liboqs_avg_gen import gen_averages

# Declaring global variables
kem_operations = ["keygen", "encaps", "decaps"]
sig_operations = ["keypair", "sign", "verify"]
kem_algs = []
sig_algs = []
dir_paths = {}
root_dir = ""
num_runs = 0


#------------------------------------------------------------------------------
def setup_parse_env() :


    global root_dir, kem_algs, sig_algs, dir_paths

    # Setting main path vars
    current_dir = os.getcwd()
    root_dir = os.path.dirname(os.path.dirname(current_dir))

    # Creating test results dir paths dict
    dir_paths['root_dir'] = os.path.dirname(os.path.dirname(current_dir))
    dir_paths['results_dir'] = os.path.join(root_dir, "test-data", "results", "liboqs")
    dir_paths['up_results'] = os.path.join(root_dir, "test-data", "up-results", "liboqs")

    # Setting the alg list filename based on version flag
    kem_algs_file = os.path.join(root_dir, "test-data", "alg-lists", "kem-algs.txt")
    sig_algs_file = os.path.join(root_dir, "test-data", "alg-lists", "sig-algs.txt")

    # Inserting the kem algs into list for later use
    with open(kem_algs_file, "r") as kem_file:
        for line in kem_file:
            kem_algs.append(line.strip())
    
    # Inserting the digital signature algs into list for later use
    with open(sig_algs_file, "r") as alg_file:
        for line in alg_file:
            sig_algs.append(line.strip())

    algs_dict = {'kem_algs': kem_algs, 'sig_algs': sig_algs}

    return algs_dict


#------------------------------------------------------------------------------
def handle_results_dir_creation(machine_num):
    """Function for handling what the user wants to do with old results"""

    # Checking if there are old parsed results for current Machine-ID and handling clashes 
    if os.path.exists(dir_paths["type_mem_dir"]) or os.path.exists(dir_paths["type_speed_dir"]):

        # Outputting warning message
        print(f"There are already parsed Liboqs testing results present for Machine-ID ({machine_num})\n")

        # Get decision from user on how to handle old results before parsing continues
        while True:

            # Outputting potential options and handling user choice
            print(f"\nFrom the following options, choose how would you like to handle the old results:\n")
            print("Option 1 - Replace old parsed results with new ones")
            print("Option 2 - Exit parsing programme to move old results and rerun after (if you choose this option, please move the entire folder not just its contents)")
            print("Option 3 - Make parsing script programme wait until you have move files before continuing")
            user_choice = input("Enter option (1/2/3): ")

            if user_choice == "1":

                # Replacing all old results and creating new empty dir to store parsed results
                print(f"Removing old results directory for Machine-ID ({machine_num}) before continuing...")
                shutil.rmtree(dir_paths["results_dir"], f"machine-{machine_num}")
                print("Old results removed")

                os.makedirs(dir_paths["type_speed_dir"])
                os.makedirs(dir_paths["type_mem_dir"])

                break

            elif user_choice == "2":

                # Exiting the script to allow the user to move old results before retrying
                print("Exiting parsing script...")
                exit()

            elif user_choice == "3":

                # Halting script until old results have been moved for current Machine-ID
                while True:
                    input(f"Halting parsing script so old parsed results for Machine-ID ({machine_num}) can be moved, press enter to continue")
                    if os.path.exists(dir_paths["type_mem_dir"]) or os.path.exists(dir_paths["type_speed_dir"]):
                        print(f"Old parsed results for Machine-ID ({machine_num}) still present!!!\n")
                    else:
                        print("Old results have been moved, now continuing with parsing script")
                        os.makedirs(dir_paths["type_speed_dir"])
                        os.makedirs(dir_paths["type_mem_dir"])
                        break
                
                break

            else:
                print("Incorrect value, please select (1/2/3)")

    else:

        # No old parsed results for current machine-id present so creating new dirs
        os.makedirs(dir_paths["type_speed_dir"])
        os.makedirs(dir_paths["type_mem_dir"])


#------------------------------------------------------------------------------
def pre_speed_processing():
    """ Function for preparing the speed up-result data to 
        by removing system information in file, allowing for
        further processing in the script """
    
    # Setting up destination dir in current machines up-results for pre-processed speed files
    if not os.path.exists(dir_paths['up_speed_dir']):
        os.makedirs(dir_paths['up_speed_dir'])
    else:
        shutil.rmtree(dir_paths["up_speed_dir"])
        os.makedirs(dir_paths['up_speed_dir'])

    # Declaring initial variables
    kem_prefix = "test-kem-speed-"
    sig_prefix = "test-sig-speed-"

    # Pre-formatting kem csv files
    for run_count in range(1, num_runs+1):

        # Setting filename based on run
        kem_pre_filename = kem_prefix + str(run_count) + ".csv"
        kem_filename = os.path.join(dir_paths["raw_speed_dir"], kem_pre_filename)

        #Getting header start index
        with open(kem_filename, 'r') as pre_file:
            rows = pre_file.readlines()

        # Getting header start index and formatting file
        header_line_index = next(row_index for row_index, line in enumerate(rows) if line.startswith('Operation'))
        kem_pre_speed_df = pd.read_csv(kem_filename, skiprows=range(header_line_index), skipfooter=1, delimiter='|', engine='python')
        kem_pre_speed_df = kem_pre_speed_df.iloc[1:]

        # Writing out pre_formatted file to up-results speed dir
        speed_dest_dir = os.path.join(dir_paths["up_speed_dir"], kem_pre_filename)
        kem_pre_speed_df.to_csv(speed_dest_dir, index=False, sep="|")

    # Pre-formatting sig csv files
    for run_count in range(1, num_runs+1):

        # Setting filename based on run
        sig_pre_filename = sig_prefix + str(run_count) + ".csv"
        sig_filename = os.path.join(dir_paths["raw_speed_dir"], sig_pre_filename)

        #Getting header start index
        with open(sig_filename, 'r') as pre_file:
            rows = pre_file.readlines()

        # Getting header start index and formatting file
        header_line_index = next(i for i, line in enumerate(rows) if line.startswith('Operation'))
        sig_pre_speed_df = pd.read_csv(sig_filename, skiprows=range(header_line_index), skipfooter=1, delimiter='|', engine='python')
        sig_pre_speed_df = sig_pre_speed_df.iloc[1:]

        # Writing out pre-formatted file to up-results speed dir
        speed_dest_dir = os.path.join(dir_paths["up_speed_dir"], sig_pre_filename)
        sig_pre_speed_df.to_csv(speed_dest_dir, index=False, sep="|")


#------------------------------------------------------------------------------
def speed_processing():
    """ Function for processing the speed up-results and 
        exporting the data into a clean CSV format """

    # Declaring initial variables
    kem_prefix = "test-kem-speed-"
    sig_prefix = "test-sig-speed-"

    # Creating algorithm list to insert into new column
    new_col_kem = [alg for alg in kem_algs for _ in range(3)]
    new_col_sig = [alg for alg in sig_algs for _ in range(3)]
    
    # Reading the original csv files and formatting
    for file_count in range(1, num_runs+1):

        """ Formatting Kem Files """
        # Loading kem file into dataframe
        filename_kem_pre = kem_prefix + str(file_count) + ".csv"
        filename_kem_pre = os.path.join(dir_paths['up_speed_dir'], filename_kem_pre)
        temp_df = pd.read_csv(filename_kem_pre, delimiter="|", index_col=False)

        # Striping trailing spaces and removing algorithms from Operation
        temp_df.columns = [col.strip() for col in temp_df.columns]
        temp_df = temp_df.loc[~temp_df['Operation'].str.strip().isin(kem_algs)]
        #temp_df = temp_df.applymap(lambda val: val.strip() if isinstance(val, str) else val)
        temp_df = temp_df.apply(lambda col: col.str.strip() if col.dtype == 'object' else col)


        # Inserting new algorithm column and outputting formatted csv
        temp_df.insert(0, "Algorithm", new_col_kem)
        filename_kem = kem_prefix + str(file_count) + ".csv"
        filename_kem = os.path.join(dir_paths['type_speed_dir'], filename_kem)
        temp_df.to_csv(filename_kem, index=False)
        
        """ Formatting Digital Signature Files """
        # Loading kem file into dataframe and striping trailing space in columns headers
        filename_sig_pre = sig_prefix + str(file_count) + ".csv"
        filename_sig_pre = os.path.join(dir_paths['up_speed_dir'], filename_sig_pre)
        temp_df = pd.read_csv(filename_sig_pre, delimiter="|", index_col=False)

        # Striping trailing spaces and removing algorithms from Operation
        temp_df.columns = [col.strip() for col in temp_df.columns]
        temp_df = temp_df.loc[~temp_df['Operation'].str.strip().isin(sig_algs)]
        #temp_df = temp_df.applymap(lambda val: val.strip() if isinstance(val, str) else val)
        temp_df = temp_df.apply(lambda col: col.str.strip() if col.dtype == 'object' else col)

        
        # Inserting new column and outputting formatted csv
        temp_df.insert(0, 'Algorithm', new_col_sig)
        filename_sig = sig_prefix + str(file_count) + ".csv"
        filename_sig = os.path.join(dir_paths['type_speed_dir'], filename_sig)
        temp_df.to_csv(filename_sig, index=False)


#------------------------------------------------------------------------------
def get_peak(mem_file, peak_metrics):
    """ Function that takes the current massif.out file and gets 
        the peak memory metrics, returning the values to continue
        processing. The function comes from the run_mem.py script 
        found in OQS Profiling Project
        https://github.com/open-quantum-safe/profiling """

    # Gets max memory metric from algorithm operation
    with open(mem_file, "r") as lines:
        peak = -1
        for line in lines:
            if line.startswith(" Detailed snapshots: ["):
                match=re.search("\d+ \(peak\).*", line)
                if match:
                    peak = int(match.group(0).split()[0])      
            if (peak > 0):
                
                if line.startswith('{: >3d}'.format(peak)): # remove "," and print all numbers except first:
                    nl = line.replace(",", "")
                    peak_metrics = nl.split()
                    del peak_metrics[0]
                    #print(" ".join(res))
                    return peak_metrics


#------------------------------------------------------------------------------
def memory_processing():
    """ Function for taking in the memory up-results, processing
        and outputting the results into a CSV format """

    # Setting directory variables and creating directories
    kem_up_dir = os.path.join(dir_paths["up_mem_dir"], "kem-mem-metrics")
    sig_up_dir = os.path.join(dir_paths["up_mem_dir"], "sig-mem-metrics")

    # Declaring the list variables used for memory processing
    new_row = []
    peak_metrics = []

    # File placeholders
    fieldnames = ["Algorithm", "Operation", "intits", "maxBytes", "maxHeap", "extHeap", "maxStack"]
    kem_operations = ["keygen", "encaps", "decaps"]
    sig_operations = ["keypair", "sign", "verify"]
    
    # Looping through the number runs specified
    for run_count in range(1, num_runs+1):

        # Creating temp dataframe
        temp_df = pd.DataFrame(columns=fieldnames)

        # Looping through the kem algorithms
        for kem_alg in kem_algs:

            #Looping the operations and adding to temp dataframe 
            for operation in range(0,3,1):

                # Parsing metrics and adding results to dataframe row
                kem_up_filename = kem_alg + "-" + str(operation) + "-" + str(run_count) + ".txt"
                kem_up_filepath = os.path.join(kem_up_dir, kem_up_filename)

                try:
                    peak_metrics = get_peak(kem_up_filepath, peak_metrics)
                    new_row.extend([kem_alg, kem_operations[operation]])
                    new_row.extend(peak_metrics)
                    
                    temp_df.loc[len(temp_df)] = new_row

                    # Clearing lists
                    peak_metrics.clear()
                    new_row.clear()
                
                except Exception as e:
                    print(f"Missing file {kem_up_filename}")
                    print(f"error - {e}")

        # Outputting kem csv file for this run
        kem_filename = "kem-mem-metrics-" + str(run_count) + ".csv"
        kem_filepath = os.path.join(dir_paths["type_mem_dir"], kem_filename)
        temp_df.to_csv(kem_filepath, index=False)

        #Looping through sig algorithms
        for sig_alg in sig_algs:

           # sig_up_filename_pre = os.path.join(sig_dir, sig_file_prefix)

            #Looping the operations and adding to temp dataframe 
            for operation in range(0,3,1):

                # Parsing metrics and adding results to dataframe row
                sig_up_filename = sig_alg + "-" + str(operation) + "-" + str(run_count) + ".txt"
                sig_up_filepath = os.path.join(sig_up_dir, sig_up_filename)

                try:
                    peak_metrics = get_peak(sig_up_filepath, peak_metrics)
                    new_row.extend((sig_alg, sig_operations[operation]))
                    new_row.extend(peak_metrics)
                    temp_df.loc[len(temp_df)] = new_row

                    # Clearing lists
                    peak_metrics.clear()
                    new_row.clear()
                
                except Exception as e:
                    print(f"Missing file {sig_up_filename}")
                    print(f"error - {e}")

        # Outputting digital signature csv file for this run
        sig_filename = "sig-mem-metrics-" + str(run_count) + ".csv"
        sig_filepath = os.path.join(dir_paths["type_mem_dir"], sig_filename)
        temp_df.to_csv(sig_filepath, index=False)


#------------------------------------------------------------------------------
def process_tests(num_machines, algs_dicts):
    """ Function for parsing the results for multiple machines 
        and stores them as csv files. Once up-results are processed
        averages are calculated for the results """
    
    global dir_paths

    # Processing the results for the machine/s
    for machine_num in range(1, num_machines+1):
        
        # Setting up directory path
        dir_paths['up_speed_dir'] = os.path.join(dir_paths['up_results'], f"machine-{str(machine_num)}", "speed-results")
        dir_paths['up_mem_dir'] = os.path.join(dir_paths['up_results'], f"machine-{str(machine_num)}", "mem-results")
        dir_paths['type_speed_dir'] = os.path.join(dir_paths['results_dir'], f"machine-{str(machine_num)}", "speed-results")
        dir_paths['type_mem_dir'] = os.path.join(dir_paths['results_dir'], f"machine-{str(machine_num)}", "mem-results")
        dir_paths['raw_speed_dir'] = os.path.join(dir_paths['up_results'], f"machine-{str(machine_num)}", "raw-speed-results")

        handle_results_dir_creation(machine_num)

        print(f"machine dir_paths dict - \n{dir_paths}")

        # Parsing results
        pre_speed_processing()
        speed_processing()
        memory_processing()

        # Calculating the averages for the parsed data
        gen_averages(dir_paths, num_runs, algs_dicts)


#------------------------------------------------------------------------------
def parse_liboqs(test_opts):
    """ Main function for controlling the liboqs up-result
        data processing and average calculation"""

    # Getting test options
    global num_runs
    num_machines = test_opts[0]
    num_runs = test_opts[1]

    # Setting up the script
    print(f"\nPreparing to Parse Liboqs Results:\n")
    algs_dict = setup_parse_env()

    # Processing the results
    print("Parsing results... ")
    process_tests(num_machines, algs_dict)
