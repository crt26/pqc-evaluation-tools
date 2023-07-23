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
from liboqs_avg_gen import gen_averages

# Declaring global variables
kem_operations = ["keygen", "encaps", "decaps"]
sig_operations = ["keypair", "sign", "verify"]
kem_algs = []
sig_algs = []
system_type = ""
root_dir = ""
num_runs = 0


#------------------------------------------------------------------------------
def get_system_type() :
    """ Function for checking the system type and setting root_dir path """
    global root_dir, system_type

    # Checking and storing system type
    if sys.platform == "win32":

        system_type = "win"
        root_dir = r"..\.."

    else:
        system_type = "linux"
        current_dir = os.getcwd()
        root_dir = os.path.dirname(os.path.dirname(current_dir))


#------------------------------------------------------------------------------*
def get_algs():
    """ Function for reading in the various algorithms into 
        an array for use within the script """

    # Checking liboqs version used to determine alg-list file
    flag_file = os.path.join(root_dir, "alg-lists", "version-flag.txt")

    with open(flag_file, "r") as flag:
        version_flag = flag.readline().strip()

    # Setting the alg list filename based on version flag
    if version_flag == "0":
        kem_algs_file = os.path.join(root_dir, "alg-lists", "kem-algs-v7.txt")
        sig_algs_file = os.path.join(root_dir, "alg-lists", "sig-algs-v7.txt")
    else:
        kem_algs_file = os.path.join(root_dir, "alg-lists", "kem-algs-v8.txt")
        sig_algs_file = os.path.join(root_dir, "alg-lists", "sig-algs-v8.txt")

    # Inserting the kem algs into list for later use
    with open(kem_algs_file, "r") as kem_file:
        for line in kem_file:
            kem_algs.append(line.strip())
    
    # Inserting the digital signature algs into list for later use
    with open(sig_algs_file, "r") as alg_file:
        for line in alg_file:
            sig_algs.append(line.strip())


#------------------------------------------------------------------------------
def pre_speed_processing(up_speed_dir, up_temp_speed_dir):
    """ Function for preparing the speed up-result data to 
        by removing system information in file, allowing for
        further processing in the script """

    # Declaring initial variables
    kem_prefix = "test-kem-speed-"
    sig_prefix = "test-sig-speed-"

    # Make speed destination directory
    if os.path.exists(up_speed_dir) is False:
        os.makedirs(up_speed_dir)
    else:
        shutil.rmtree(up_speed_dir)
        os.makedirs(up_speed_dir)

    # Pre-formatting kem csv files
    for run_count in range(1, num_runs+1):

        # Setting filename based on run
        kem_pre_filename = kem_prefix + str(run_count) + ".csv"
        kem_filename = os.path.join(up_temp_speed_dir, kem_pre_filename)

        #Getting header start index
        with open(kem_filename, 'r') as pre_file:
            rows = pre_file.readlines()

        # Getting header start index and formatting file
        header_line_index = next(row_index for row_index, line in enumerate(rows) if line.startswith('Operation'))
        kem_pre_speed_df = pd.read_csv(kem_filename, skiprows=range(header_line_index), skipfooter=1, delimiter='|', engine='python')
        kem_pre_speed_df = kem_pre_speed_df.iloc[1:]

        # Writing out pre_formatted file to up-results speed dir
        speed_dest_dir = os.path.join(up_speed_dir, kem_pre_filename)
        kem_pre_speed_df.to_csv(speed_dest_dir, index=False, sep="|")

    # Pre-formatting sig csv files
    for run_count in range(1, num_runs+1):

        # Setting filename based on run
        sig_pre_filename = sig_prefix + str(run_count) + ".csv"
        sig_filename = os.path.join(up_temp_speed_dir, sig_pre_filename)

        #Getting header start index
        with open(sig_filename, 'r') as pre_file:
            rows = pre_file.readlines()

        # Getting header start index and formatting file
        header_line_index = next(i for i, line in enumerate(rows) if line.startswith('Operation'))
        sig_pre_speed_df = pd.read_csv(sig_filename, skiprows=range(header_line_index), skipfooter=1, delimiter='|', engine='python')
        sig_pre_speed_df = sig_pre_speed_df.iloc[1:]

        # Writing out pre-formatted file to up-results speed dir
        speed_dest_dir = os.path.join(up_speed_dir, sig_pre_filename)
        sig_pre_speed_df.to_csv(speed_dest_dir, index=False, sep="|")


#------------------------------------------------------------------------------
def speed_processing(type_speed_dir, up_speed_dir):
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
        filename_kem_pre = os.path.join(up_speed_dir, filename_kem_pre)
        temp_df = pd.read_csv(filename_kem_pre, delimiter="|", index_col=False)

        # Striping trailing spaces and removing algorithms from Operation
        temp_df.columns = [col.strip() for col in temp_df.columns]
        temp_df = temp_df.loc[~temp_df['Operation'].str.strip().isin(kem_algs)]
        temp_df = temp_df.applymap(lambda val: val.strip() if isinstance(val, str) else val)

        # Inserting new algorithm column and outputting formatted csv
        temp_df.insert(0, "Algorithm", new_col_kem)
        filename_kem = kem_prefix + str(file_count) + ".csv"
        filename_kem = os.path.join(type_speed_dir, filename_kem)
        temp_df.to_csv(filename_kem, index=False)
        
        """ Formatting Digital Signature Files """
        # Loading kem file into dataframe and striping trailing space in columns headers
        filename_sig_pre = sig_prefix + str(file_count) + ".csv"
        filename_sig_pre = os.path.join(up_speed_dir, filename_sig_pre)
        temp_df = pd.read_csv(filename_sig_pre, delimiter="|", index_col=False)

        # Striping trailing spaces and removing algorithms from Operation
        temp_df.columns = [col.strip() for col in temp_df.columns]
        temp_df = temp_df.loc[~temp_df['Operation'].str.strip().isin(sig_algs)]
        temp_df = temp_df.applymap(lambda val: val.strip() if isinstance(val, str) else val)
        
        # Inserting new column and outputting formatted csv
        temp_df.insert(0, 'Algorithm', new_col_sig)
        filename_sig = sig_prefix + str(file_count) + ".csv"
        filename_sig = os.path.join(type_speed_dir, filename_sig)
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
def memory_processing(type_mem_dir, up_mem_dir):
    """ Function for taking in the memory up-results, processing
        and outputting the results into a CSV format """

    # Setting directory variables
    kem_dir = os.path.join(up_mem_dir, "kem-mem-metrics")
    sig_dir = os.path.join(up_mem_dir, "sig-mem-metrics")
    kem_file_prefix = "kem-mem-metrics"
    sig_file_prefix = "sig-mem-metrics"

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

            kem_up_filename_pre = os.path.join(kem_dir,kem_file_prefix)

            #Looping the operations and adding to temp dataframe 
            for operation in range(0,3,1):

                # Parsing metrics and adding results to dataframe row
                kem_up_filename = kem_up_filename_pre + "-" + kem_alg + "-" + str(operation) + "-" + str(run_count) + ".txt"

                peak_metrics = get_peak(kem_up_filename, peak_metrics)
                new_row.extend([kem_alg, kem_operations[operation]])
                new_row.extend(peak_metrics)
                
                temp_df.loc[len(temp_df)] = new_row

                # Clearing lists
                peak_metrics.clear()
                new_row.clear()

        # Outputting kem csv file for this run
        kem_end = "kem-mem-metrics-" + str(run_count) + ".csv"
        kem_filename = os.path.join(type_mem_dir, kem_end)
        temp_df.to_csv(kem_filename, index=False)

        #Looping through sig algorithms
        for sig_alg in sig_algs:

            sig_up_filename_pre = os.path.join(sig_dir, sig_file_prefix)

            #Looping the operations and adding to temp dataframe 
            for operation in range(0,3,1):

                # Parsing metrics and adding results to dataframe row
                sig_up_filename = sig_up_filename_pre + "-" + sig_alg + "-" + str(operation) + "-" + str(run_count) + ".txt"
                peak_metrics = get_peak(sig_up_filename, peak_metrics)
                new_row.extend((sig_alg, sig_operations[operation]))
                new_row.extend(peak_metrics)
                temp_df.loc[len(temp_df)] = new_row

                # Clearing lists
                peak_metrics.clear()
                new_row.clear()

        # Outputting digital signature csv file for this run
        sig_end = "sig-mem-metrics-" + str(run_count) + ".csv"
        sig_filename = os.path.join(type_mem_dir, sig_end)
        temp_df.to_csv(sig_filename, index=False)


#------------------------------------------------------------------------------
def process_tests(num_machines):
    """ Function for parsing the results for multiple machines 
        and stores them as csv files. Once up-results are processed
        averages are calculated for the results """

    # Declaring directory variables used for test processing
    results_dir = os.path.join(root_dir, "results")
    mem_dir = os.path.join(results_dir, "liboqs", "mem-results")
    speed_dir = os.path.join(results_dir, "liboqs", "speed-results")
    up_mem = os.path.join(root_dir, "up-results", "liboqs", "mem-results")
    up_speed = os.path.join(root_dir, "up-results", "liboqs", "speed-results")
    up_temp_speed = os.path.join(root_dir, "up-results", "liboqs", "temp-speed-results")

    # Creating directory structure and removing previous results
    try: 

        # Making results directory structure
        os.makedirs(mem_dir)
        os.makedirs(speed_dir)
    
    except:

        # Removing the previous results
        shutil.rmtree(mem_dir)
        shutil.rmtree(speed_dir)
        os.makedirs(mem_dir)
        os.makedirs(speed_dir)

    # Processing the results for the machine/s
    for machine_num in range(1, num_machines+1):

        type_name = "machine-" + str(machine_num)
        
        # Setting up directory path
        up_speed_dir = os.path.join(up_speed, type_name)
        up_temp_speed_dir = os.path.join(up_temp_speed, type_name)
        up_mem_dir = os.path.join(up_mem, type_name)

        # Creating specific result directories and clearing old results
        try: 
            
            # Speed result directories
            type_speed_dir = os.path.join(speed_dir, type_name)
            os.makedirs(type_speed_dir)

            # Mem result directories
            type_mem_dir = os.path.join(mem_dir, type_name)
            os.makedirs(type_mem_dir)

        except:

            # Setting the directory variables
            type_speed_dir = os.path.join(speed_dir, type_name)
            type_mem_dir = os.path.join(mem_dir, type_name)

            #Clearing the old results and making directories
            shutil.rmtree(type_speed_dir)
            shutil.rmtree(type_mem_dir)
            os.makedirs(type_speed_dir)
            os.makedirs(type_mem_dir)

        # Parsing results
        pre_speed_processing(up_speed_dir, up_temp_speed_dir)
        speed_processing(type_speed_dir, up_speed_dir)
        memory_processing(type_mem_dir, up_mem_dir)

        # Calculating the averages for the parsed data
        gen_averages(type_speed_dir, type_mem_dir, root_dir, num_runs)


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
    get_system_type()
    get_algs()

    # Processing the results
    print("Parsing results... ")
    process_tests(num_machines)
