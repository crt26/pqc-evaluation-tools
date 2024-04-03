"""
Copyright (c) 2023 Callum Turino
SPDX-License-Identifier: MIT

This python script contains the functions for calculating the averages liboqs result
files and then outputs the average calculation into CSV format within the respective
machine's result directory.

"""

#------------------------------------------------------------------------------
import pandas as pd
import os

# Declaring global variables
kem_algs = []
sig_algs = []
kem_operations = ["keygen", "encaps", "decaps"]
sig_operations = ["keypair", "sign", "verify"]
root_dir = ""
num_runs=0


#------------------------------------------------------------------------------
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

    # Getting the kem algs
    with open(kem_algs_file, "r") as kem_file:
        for line in kem_file:
            kem_algs.append(line.strip())
    
    # Getting the digital signature algorithms
    with open(sig_algs_file, "r") as alg_file:
        for line in alg_file:
            sig_algs.append(line.strip())


#------------------------------------------------------------------------------
def avg_mem(type_mem_dir):
    """ Function for taking in the provided memory 
        results and generating an average for all the runs for
        that current machine """

    # Declaring filepath prefix variables
    kem_mem_file_prefix = os.path.join(type_mem_dir, "kem-mem-metrics-")
    sig_mem_file_prefix = os.path.join(type_mem_dir, "sig-mem-metrics-")

    # Declaring dataframes and fieldnames
    mem_fieldnames = ["Algorithm", "Operation", "intits", "maxBytes", "maxHeap", "extHeap", "maxStack"]
    kem_mem_avg = pd.DataFrame(columns=mem_fieldnames)
    sig_mem_avg = pd.DataFrame(columns=mem_fieldnames)

    """ Calculating KEM Memory Averages """
    # Looping through the kem algorithms
    for kem_alg in kem_algs:

        # Creating combined operations dataframe for current algorithm
        combined_operations = pd.DataFrame(columns=mem_fieldnames)

        # Looping through the run files
        for run_count in range(1, num_runs+1):

            # Setting filename and reading csv into dataframe
            kem_mem_filename = kem_mem_file_prefix + str(run_count) + ".csv"
            temp_df = pd.read_csv(kem_mem_filename)

            # Getting the algorithm operations across all files into one
            temp_df = temp_df.loc[temp_df["Algorithm"].str.contains(kem_alg)]
            combined_operations = pd.concat([temp_df, combined_operations], ignore_index=True, sort=False)
        
        # Getting the averages for each operation
        for operation in kem_operations:
            
            # Getting a list of the operation metric averages 
            operation_average = combined_operations.loc[combined_operations["Operation"].str.contains(operation)]
            operation_average = operation_average[mem_fieldnames[2:]]

            # Calculating Averages for kem results
            operation_average = (operation_average.mean(axis=0)).to_frame()
                        
            #Creating new row and exporting to main kem memory average dataframe
            row = operation_average.iloc[:, 0].to_list()
            row.insert(0, kem_alg)
            row.insert(1, operation)
            kem_mem_avg.loc[len(kem_mem_avg)] = row

    """ Calculating Digital Signature Memory Averages """
    # Looping through digital signature algorithms
    for sig_alg in sig_algs:

        # Creating combined operations dataframe for current algorithm
        combined_operations = pd.DataFrame(columns=mem_fieldnames)

        # Looping through run files
        for run_count in range(1, num_runs+1):

            # Setting the filename and reading csv into dataframe
            sig_mem_filename = sig_mem_file_prefix + str(run_count) + ".csv"
            temp_df = pd.read_csv(sig_mem_filename)

            # Getting the algorithm operations across all files into one
            temp_df = temp_df.loc[temp_df["Algorithm"].str.contains(sig_alg, regex=False)]
            combined_operations = pd.concat([temp_df, combined_operations], ignore_index=True, sort=False)

        # Getting the averages for each operation
        for operation in sig_operations:

            # Creating a list of the operation metric averages
            operation_average = combined_operations.loc[combined_operations["Operation"].str.contains(operation, regex=False)]
            operation_average = operation_average[mem_fieldnames[2:]]

            # Calculating averages
            operation_average = (operation_average.mean(axis=0)).to_frame()

            # Creating new row and exporting to main digital signature memory average dataframe
            row = operation_average.iloc[:, 0].to_list()
            row.insert(0, sig_alg)
            row.insert(1, operation)
            sig_mem_avg.loc[len(sig_mem_avg)] = row

    # Exporting average csv files
    kem_csv_name = os.path.join(type_mem_dir, "kem-mem-avg.csv")
    kem_mem_avg.to_csv(kem_csv_name, index=False)
    sig_csv_name = os.path.join(type_mem_dir, "sig-mem-avg.csv")
    sig_mem_avg.to_csv(sig_csv_name, index=False)


#------------------------------------------------------------------------------
def avg_speed(type_speed_dir):
    """ Function for taking in the provided speed 
        results and generating an average for all the runs for
        that current machine """

    # Declaring filepath prefix variables and fieldnames list
    kem_filename_prefix = os.path.join(type_speed_dir, "test-kem-speed-")
    sig_filename_prefix = os.path.join(type_speed_dir, "test-sig-speed-")
    speed_fieldnames = []

    # Getting fieldnames through first file
    test_filename = "test-kem-speed-1.csv"
    test_filename = os.path.join(type_speed_dir, test_filename)

    # Loading test file into dataframe and getting headers into list
    check_df = pd.read_csv(test_filename)
    speed_fieldnames = check_df.columns.to_list()

    # Setting output dataframe headers
    kem_speed_avg = pd.DataFrame(columns=speed_fieldnames)
    sig_speed_avg = pd.DataFrame(columns=speed_fieldnames)

    """ Calculating KEM Speed Averages """
    # Looping through kem algorithms
    for kem_alg in kem_algs:

        # Creating combined averages dataframe
        combined_operations = pd.DataFrame(columns=speed_fieldnames)

        # Looping through run files
        for run_count in range(1, num_runs+1):

            # Setting filename and reading csv into dataframe
            kem_filename = kem_filename_prefix + str(run_count) + ".csv"
            temp_df = pd.read_csv(kem_filename)

            # Getting the algorithm operations across all files into one
            temp_df = temp_df.loc[temp_df["Algorithm"].str.contains(kem_alg, regex=False)]
            combined_operations = pd.concat([temp_df, combined_operations], ignore_index=True, sort=False)
        
        # Getting the average for each operation
        for operation in kem_operations:

            # Creating a list of operation metric averages
            operation_average = combined_operations.loc[combined_operations["Operation"].str.contains(operation, regex=False)]
            operation_average = operation_average[speed_fieldnames[2:]]

            # Calculating Average
            operation_average = (operation_average.mean(axis=0)).to_frame()

            # Creating new row and exporting to main kem speed average dataframe
            row = operation_average.iloc[:, 0].to_list()
            row.insert(0, kem_alg)
            row.insert(1, operation)
            kem_speed_avg.loc[len(kem_speed_avg)] = row

    """ Calculating Digital Signature Speed Averages """
    # Looping through sig algorithms
    for sig_alg in sig_algs:

        # Creating combined averages dataframe
        combined_operations = pd.DataFrame(columns=speed_fieldnames)

        # Looping through run files
        for run_count in range(1, num_runs+1):

            # Setting filename and reading csv into dataframe
            sig_filename = sig_filename_prefix + str(run_count) + ".csv"
            temp_df = pd.read_csv(sig_filename)

            # Getting the algorithm operations across all files into one
            temp_df = temp_df.loc[temp_df["Algorithm"].str.contains(sig_alg, regex=False)]
            combined_operations = pd.concat([temp_df, combined_operations], ignore_index=True, sort=False)
        
        # Getting the average for each operation
        for operation in sig_operations:

            # Creating a list of operation metric averages
            operation_average = combined_operations.loc[combined_operations["Operation"].str.contains(operation, regex=False)]
            operation_average = operation_average[speed_fieldnames[2:]]

            # Calculating Average
            operation_average = (operation_average.mean(axis=0)).to_frame()

            # Creating new row and exporting to main digital signature speed average dataframe
            row = operation_average.iloc[:, 0].to_list()
            row.insert(0, sig_alg)
            row.insert(1, operation)
            sig_speed_avg.loc[len(sig_speed_avg)] = row

    # Exporting average csv files
    kem_csv_name = os.path.join(type_speed_dir, "kem-speed-avg.csv")
    kem_speed_avg.to_csv(kem_csv_name, index=False)
    sig_csv_name = os.path.join(type_speed_dir, "sig-speed-avg.csv")
    sig_speed_avg.to_csv(sig_csv_name, index=False)


#------------------------------------------------------------------------------
def gen_averages(type_speed_dir, type_mem_dir, dir, total_runs):
    """ Main function for controlling the liboqs average
        calculations """

    # Setting root directory and number of runs parameter
    global root_dir, kem_algs, sig_algs, num_runs
    root_dir = dir
    num_runs = total_runs
    
    # Setting the required algorithm lists
    get_algs()

    # Running average generation functions
    avg_mem(type_mem_dir)
    avg_speed(type_speed_dir)
    
    # Clearing algorithm lists
    kem_algs.clear()
    sig_algs.clear()