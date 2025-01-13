"""
Copyright (c) 2024 Callum Turino
SPDX-License-Identifier: MIT

This script provides the classes and methods for generating the average metric files for the various Liboqs and OQS-Provider results.
The script will take in the provided results and generate an average for all the runs for that current machine. The script will output
the average metric files for the various results passed to it. The classes are called by the relevant parsing script and is not intended
to be run as a standalone script.

"""

#-----------------------------------------------------------------------------------------------------------
from pdb import run
import pandas as pd
import os

#-----------------------------------------------------------------------------------------------------------
class LiboqsResultAverager:

    #------------------------------------------------------------------------------
    def __init__(self, dir_paths, kem_algs, sig_algs, num_runs, alg_operations):
        """ A class that contains needed for creating the metric average files for the various Liboqs 
            memory and CPU benchmarking results"""

        # Setting class variables for use in the class methods
        self.dir_paths = dir_paths
        self.num_runs = num_runs
        self.kem_algs = kem_algs
        self.sig_algs = sig_algs
        self.alg_operations = alg_operations

    #------------------------------------------------------------------------------
    def avg_mem(self):
        """ Method for taking in the provided memory 
            results and generating an average for all the runs for
            that current machine """

        # Declaring filepath prefix variables
        kem_mem_file_prefix = os.path.join(self.dir_paths['type_mem_dir'], "kem-mem-metrics-")
        sig_mem_file_prefix = os.path.join(self.dir_paths['type_mem_dir'], "sig-mem-metrics-")

        # Declaring dataframes and fieldnames
        mem_fieldnames = ["Algorithm", "Operation", "intits", "maxBytes", "maxHeap", "extHeap", "maxStack"]
        kem_mem_avg = pd.DataFrame(columns=mem_fieldnames)
        sig_mem_avg = pd.DataFrame(columns=mem_fieldnames)

        """ Calculating KEM Memory Averages """
        # Looping through the kem algorithms
        for kem_alg in self.kem_algs:

            # Creating combined operations dataframe for current algorithm
            combined_operations = pd.DataFrame(columns=mem_fieldnames)

            # Looping through the results files for the number of test runs
            for run_count in range(1, self.num_runs+1):

                # Setting filename and reading csv into dataframe
                kem_mem_filename = kem_mem_file_prefix + str(run_count) + ".csv"
                temp_df = pd.read_csv(kem_mem_filename)

                # Getting the operations for the current algorithm across all files into one
                if run_count == 1:
                    combined_operations = temp_df.loc[temp_df["Algorithm"].str.contains(kem_alg, regex=False)]
                else:
                    temp_df = temp_df.loc[temp_df["Algorithm"].str.contains(kem_alg, regex=False)]
                    combined_operations = pd.concat([temp_df, combined_operations], ignore_index=True, sort=False)
            
            # Getting the averages for each kem operation
            for operation in self.alg_operations['kem_operations']:
                
                # Getting a list of the operation metric averages 
                operation_average = combined_operations.loc[combined_operations["Operation"].str.contains(operation)]
                operation_average = operation_average[mem_fieldnames[2:]]

                # Calculating Averages for kem results
                operation_average = (operation_average.mean(axis=0)).to_frame()
                            
                # Creating new row and exporting to main kem memory average dataframe
                row = operation_average.iloc[:, 0].to_list()
                row.insert(0, kem_alg)
                row.insert(1, operation)
                kem_mem_avg.loc[len(kem_mem_avg)] = row

        """ Calculating Digital Signature Memory Averages """
        # Looping through digital signature algorithms
        for sig_alg in self.sig_algs:

            # Creating combined operations dataframe for current algorithm
            combined_operations = pd.DataFrame(columns=mem_fieldnames)

            # Looping through run files
            for run_count in range(1, self.num_runs+1):

                # Setting the filename and reading csv into dataframe
                sig_mem_filename = sig_mem_file_prefix + str(run_count) + ".csv"
                temp_df = pd.read_csv(sig_mem_filename)

                # Getting the operations for the current algorithm across all files into one
                if run_count == 1:
                    combined_operations = temp_df.loc[temp_df["Algorithm"].str.contains(sig_alg, regex=False)]
                else:
                    temp_df = temp_df.loc[temp_df["Algorithm"].str.contains(sig_alg, regex=False)]
                    combined_operations = pd.concat([temp_df, combined_operations], ignore_index=True, sort=False)

            # Getting the averages for each signature operation
            for operation in self.alg_operations['sig_operations']:

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
        kem_csv_name = os.path.join(self.dir_paths['type_mem_dir'], "kem-mem-avg.csv")
        kem_mem_avg.to_csv(kem_csv_name, index=False)
        sig_csv_name = os.path.join(self.dir_paths['type_mem_dir'], "sig-mem-avg.csv")
        sig_mem_avg.to_csv(sig_csv_name, index=False)

    #------------------------------------------------------------------------------
    def avg_speed(self):
        """ Method for taking in the provided speed 
            results and generating an average for all the runs for
            that current machine """

        # Declaring filepath prefix variables and fieldnames list
        kem_filename_prefix = os.path.join(self.dir_paths['type_speed_dir'], "test-kem-speed-")
        sig_filename_prefix = os.path.join(self.dir_paths['type_speed_dir'], "test-sig-speed-")
        speed_fieldnames = []

        # Getting fieldnames through first file
        test_filename = "test-kem-speed-1.csv"
        test_filename = os.path.join(self.dir_paths['type_speed_dir'], test_filename)

        # Loading test file into dataframe and getting headers into list
        check_df = pd.read_csv(test_filename)
        speed_fieldnames = check_df.columns.to_list()

        # Setting output dataframe headers
        kem_speed_avg = pd.DataFrame(columns=speed_fieldnames)
        sig_speed_avg = pd.DataFrame(columns=speed_fieldnames)

        """ Calculating KEM Speed Averages """
        # Looping through kem algorithms
        for kem_alg in self.kem_algs:

            # Creating combined averages dataframe
            combined_operations = pd.DataFrame(columns=speed_fieldnames)

            # Looping through run files
            for run_count in range(1, self.num_runs+1):

                # Setting filename and reading csv into dataframe
                kem_filename = kem_filename_prefix + str(run_count) + ".csv"
                temp_df = pd.read_csv(kem_filename)

                # Getting the algorithm operations across all files into one
                if run_count == 1:
                    combined_operations = temp_df.loc[temp_df["Algorithm"].str.contains(kem_alg, regex=False)]
                else:
                    temp_df = temp_df.loc[temp_df["Algorithm"].str.contains(kem_alg, regex=False)]
                    combined_operations = pd.concat([temp_df, combined_operations], ignore_index=True, sort=False)

            # Getting the average for each operation
            for operation in self.alg_operations['kem_operations']:

                # Creating a list of operation metric averages
                operation_average = combined_operations.loc[combined_operations["Operation"].str.contains(operation, regex=False)]
                operation_average = operation_average[speed_fieldnames[2:]]

                # Calculating average for the operation
                operation_average = (operation_average.mean(axis=0)).to_frame()

                # Creating new row and exporting to main kem speed average dataframe
                row = operation_average.iloc[:, 0].to_list()
                row.insert(0, kem_alg)
                row.insert(1, operation)
                kem_speed_avg.loc[len(kem_speed_avg)] = row

        """ Calculating Digital Signature Speed Averages """
        # Looping through sig algorithms
        for sig_alg in self.sig_algs:

            # Creating combined averages dataframe
            combined_operations = pd.DataFrame(columns=speed_fieldnames)

            # Looping through run files
            for run_count in range(1, self.num_runs+1):

                # Setting filename and reading csv into dataframe
                sig_filename = sig_filename_prefix + str(run_count) + ".csv"
                temp_df = pd.read_csv(sig_filename)

                # Getting the algorithm operations across all files into one
                if run_count == 1:
                    combined_operations = temp_df.loc[temp_df["Algorithm"].str.contains(sig_alg, regex=False)]
                else:
                    temp_df = temp_df.loc[temp_df["Algorithm"].str.contains(sig_alg, regex=False)]
                    combined_operations = pd.concat([temp_df, combined_operations], ignore_index=True, sort=False)
            
            # Getting the average for each operation
            for operation in self.alg_operations['sig_operations']:

                # Creating a list of operation metric averages
                operation_average = combined_operations.loc[combined_operations["Operation"].str.contains(operation, regex=False)]
                operation_average = operation_average[speed_fieldnames[2:]]

                # Calculating average for the operation
                operation_average = (operation_average.mean(axis=0)).to_frame()

                # Creating new row and exporting to main digital signature speed average dataframe
                row = operation_average.iloc[:, 0].to_list()
                row.insert(0, sig_alg)
                row.insert(1, operation)
                sig_speed_avg.loc[len(sig_speed_avg)] = row

        # Exporting average csv files
        kem_csv_name = os.path.join(self.dir_paths['type_speed_dir'], "kem-speed-avg.csv")
        kem_speed_avg.to_csv(kem_csv_name, index=False)
        sig_csv_name = os.path.join(self.dir_paths['type_speed_dir'], "sig-speed-avg.csv")
        sig_speed_avg.to_csv(sig_csv_name, index=False)

#-----------------------------------------------------------------------------------------------------------
class OqsProviderResultAverager:

    #------------------------------------------------------------------------------
    def __init__(self, dir_paths, num_runs, algs_dict, pqc_type_vars, col_headers):
        """ A class that contains needed for creating the metric average files for the various OQS-Provider 
            TLS benchmarking results"""
        
        # Setting class variables for use in the class methods
        self.dir_paths = dir_paths
        self.num_runs = num_runs
        self.algs_dict = algs_dict
        self.pqc_type_vars = pqc_type_vars
        self.col_headers = col_headers

    #------------------------------------------------------------------------------
    def gen_pqc_avgs(self):
        """ Method for taking in the provided PQC TLS handshake
            results and generating an average for all the runs for
            that current machine """
       
        # Process result averages for both PQC (0) and PQC-Hybrid (1) TLS test types
        for type_index in range (0,2):

            # Looping through each signing algorithm
            for sig in self.algs_dict[self.pqc_type_vars["sig_alg_type"][type_index]]:

                # Getting current signing algorithm from sig_path
                sig_path = os.path.join(self.dir_paths[self.pqc_type_vars['results_type'][type_index]], sig)

                # Creating dataframes and filepaths
                sig_avg_df = pd.DataFrame(columns=self.col_headers['pqc_based_headers'])
                
                # Getting sig/kem averages by reading in the average for specific kem across all runs
                for kem in self.algs_dict[self.pqc_type_vars["kem_alg_type"][type_index]]:

                    # Resetting combined sig dataframe
                    sig_first_combined_df = pd.DataFrame(columns=self.col_headers['pqc_based_headers'])
                    sig_reused_combined_df = pd.DataFrame(columns=self.col_headers['pqc_based_headers'])

                    # Looping through runs
                    for current_run in range(1, self.num_runs+1):

                        # Setting current run filepath
                        current_run_filename = f"tls-handshake-{sig}-run-{current_run}.csv"
                        current_run_filepath = os.path.join(sig_path, current_run_filename)

                        # Reading in current run csv to get metrics
                        current_run_df = pd.read_csv(current_run_filepath)

                        # Extracting the data for the current kem
                        kem_df = current_run_df[current_run_df["KEM Algorithm"].str.contains(kem, regex=False)]

                        # Separating the data into combined dataframes
                        if current_run == 1:
                            sig_first_combined_df = kem_df.iloc[0:1]
                            sig_reused_combined_df = kem_df.iloc[1:2]
                        else:
                            sig_first_combined_df = pd.concat([sig_first_combined_df, kem_df.iloc[0:1]])
                            sig_reused_combined_df = pd.concat([sig_reused_combined_df, kem_df.iloc[1:2]])
    
                        # Defining the average rows
                        sig_first_average_row = [sig, kem, ""]
                        sig_reused_average_row = [sig, kem, "*"]
                    
                    # Get average value for each column and append to new row var
                    for column in self.col_headers['pqc_based_headers']:
                        if column in self.col_headers['pqc_based_headers'][:3]:
                            continue
                        else:
                            sig_first_average_row.append(float(sig_first_combined_df[column].mean()))
                            sig_reused_average_row.append(float(sig_reused_combined_df[column].mean()))
                    
                    # Append average rows onto the average dataframe
                    sig_avg_df.loc[len(sig_avg_df)] = sig_first_average_row
                    sig_avg_df.loc[len(sig_avg_df)] = sig_reused_average_row

                # Output averages for the current signing algorithm to csv file
                avg_out_filename = f"tls-handshake-{sig}-avg.csv"
                avg_out_filepath = os.path.join(sig_path, avg_out_filename)
                sig_avg_df.to_csv(avg_out_filepath, index=False)

    #------------------------------------------------------------------------------
    def gen_classic_avgs(self):
        """ Method for taking in the provided classic TLS handshake
            results and generating an average for all the runs for
            that current machine """

        # Declaring main average dataframe
        classic_avg_df = pd.DataFrame(columns=self.col_headers['classic_headers'])

        # Loop through all ciphersuites
        for cipher in self.algs_dict['ciphers']:

            # Loop through all ECC curves
            for alg in self.algs_dict['classic_algs']:

                # Resetting combined curve dataframe
                curve_first_combined_df = pd.DataFrame(columns=self.col_headers['classic_headers'])
                curve_reused_combined_df = pd.DataFrame(columns=self.col_headers['classic_headers'])

                # Looping through all the runs
                for current_run in range(1, self.num_runs+1):

                    # Setting current run filepath
                    current_run_filename = f"classic-results-run-{str(current_run)}.csv"
                    current_run_filepath = os.path.join(self.dir_paths['classic_handshake_results'], current_run_filename)

                    # Reading in current run csv to get metrics
                    current_run_df = pd.read_csv(current_run_filepath)

                    # Extracting the data for the current curve and ciphersuite
                    cipher_df = current_run_df[current_run_df["Ciphersuite"].str.contains(cipher, regex=False)]
                    curve_df = cipher_df[cipher_df["Classic Algorithm"].str.contains(alg, regex=False)]

                    # Separating the data into combined dataframes
                    if current_run == 1:
                        curve_first_combined_df = curve_df.iloc[0:1]
                        curve_reused_combined_df = curve_df.iloc[1:2]
                    else:
                        curve_first_combined_df = pd.concat([curve_first_combined_df, curve_df.iloc[0:1]])
                        curve_reused_combined_df = pd.concat([curve_first_combined_df, curve_df.iloc[1:2]])

                # Calculating Averages
                curve_first_combined_row = [cipher, alg, ""]
                curve_reused_combined_row = [cipher, alg, "*"]

                # Get average value for each column and append to new row variable
                for column in self.col_headers['classic_headers']:
                    if column in self.col_headers['classic_headers'][:3]:
                        continue
                    else:
                        curve_first_combined_row.append(float(curve_first_combined_df[column].mean()))
                        curve_reused_combined_row.append(float(curve_reused_combined_df[column].mean()))
                
                # Append average rows onto main average dataframe
                classic_avg_df.loc[len(classic_avg_df)] = curve_first_combined_row
                classic_avg_df.loc[len(classic_avg_df)] = curve_reused_combined_row

        # Output averages to csv file
        avg_out_filename = f"classic-speed-avg.csv"
        avg_out_filepath = os.path.join(self.dir_paths['classic_handshake_results'], avg_out_filename)
        classic_avg_df.to_csv(avg_out_filepath, index=False)

    #------------------------------------------------------------------------------
    def get_speed_algs(self, temp_filename, dir_list):
        """ Method for getting the algorithms present in the speed results files """

        # Setting filepath for the current algorithm file
        temp_alg_filepath = os.path.join(dir_list[1], temp_filename)

        # Getting algorithms present in the current speed file
        temp_alg_df = pd.read_csv(temp_alg_filepath)
        algs = temp_alg_df["Algorithm"].to_list()

        return algs

    #------------------------------------------------------------------------------
    def gen_speed_avgs(self, speed_headers):
        """ Method for taking in the provided TLS speed results 
            and generating an average for all the runs for the current machine """
        
        # Defining alg_types list for average processing
        alg_types = ["kem", "sig"]

        # Loop through test types and process averages for speed metrics
        for test_type, dir_list in self.dir_paths["speed_types_dirs"].items():

            # Set file prefix depending on test type
            pqc_fileprefix = "tls-speed" if test_type == "pqc" else "tls-speed-hybrid"

            # Process both KEM and Sig averages for the current test type
            for alg_type in alg_types:

                # Getting algorithms present in for current test/alg type being processed
                temp_filename = f"{pqc_fileprefix}-{alg_type}-1.csv"
                algs = self.get_speed_algs(temp_filename, dir_list)

                # Setting headers used in csv files based on alg_type and creating dataframe
                headers = speed_headers[0] if alg_type == "kem" else speed_headers[1]
                speed_avg_df = pd.DataFrame(columns=headers)

                # Looping through the algs to get combined average dataframes
                for alg in algs:

                    # Setting clean combined alg speed dataframe
                    combined_df = pd.DataFrame(columns=headers)

                    # Looping through the runs to get averages for alg type
                    for run_num in range(1, self.num_runs+1):

                        # Setting filename and path for current type and run
                        current_filename = f"{pqc_fileprefix}-{alg_type}-{run_num}.csv"
                        current_filepath = os.path.join(dir_list[1], current_filename)
                    
                        # Pulling in the algorithm values for the current run and alg
                        current_run_df = pd.read_csv(current_filepath)
                        current_run_df = current_run_df[current_run_df["Algorithm"].str.contains(alg, regex=False)]

                        # Adding algorithm values to the combined dataframe that will be used to get averages for the alg across runs
                        if run_num == 1:
                            combined_df = current_run_df.loc[current_run_df['Algorithm'].str.contains(alg, regex=False)]
                        else:
                            combined_df = pd.concat([combined_df, current_run_df.iloc[0:1]])

                    # Get average value for each column and append to new row var
                    speed_avg_row = []
                    
                    for column in headers:
                        if column in headers[0]:
                            continue
                        else:
                            speed_avg_row.append(float(combined_df[column].mean()))

                    # Appending row to main average dataframe
                    speed_avg_row.insert(0, alg)
                    speed_avg_df.loc[len(speed_avg_df)] = speed_avg_row

                # Exporting TLS speed averages to csv file
                speed_avg_filename = f"{pqc_fileprefix}-{alg_type}-avg.csv"
                speed_avg_filepath = os.path.join(dir_list[1], speed_avg_filename)
                speed_avg_df.to_csv(speed_avg_filepath, index=False)