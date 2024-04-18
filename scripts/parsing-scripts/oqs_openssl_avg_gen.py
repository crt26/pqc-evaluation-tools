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
import sys

# Declaring global variables
dir_paths = {}
kem_algs = []
sig_algs = []
ciphers = []
classic_algs = []
speed_sig_algs = []
speed_kem_algs = []
root_dir = ""
num_runs = 0


#------------------------------------------------------------------------------
def gen_pqc_avgs(col_headers):
    """ Function for taking in the provided PQC TLS handshake
        results and generating an average for all the runs for
        that current machine """
    
    count = 1

    # Looping through each signing algorithm
    for sig in sig_algs:

        # Getting current signing sig from sig_path
        sig_path = os.path.join(dir_paths['pqc_handshake_results'], sig)

        # Creating dataframes and filepaths
        sig_avg_df = pd.DataFrame(columns=col_headers['pqc_headers'])
        
        # Getting sig/kem averages by getting the average for specific kem from all runs
        for kem in kem_algs:

            # Resetting combined sig dataframe
            sig_first_combined_df = pd.DataFrame(columns=col_headers['pqc_headers'])
            sig_reused_combined_df = pd.DataFrame(columns=col_headers['pqc_headers'])

            # Looping through runs
            for current_run in range(1, num_runs+1):

                # Setting current run filepath
                current_run_filename = f"tls-handshake-{sig}-run-{current_run}.csv"
                current_run_filepath = os.path.join(sig_path, current_run_filename)

                # Reading in current run csv to get metrics
                current_run_df = pd.read_csv(current_run_filepath)

                kem_df = current_run_df[current_run_df["KEM Algorithm"].str.contains(kem, regex=False)]

                # Extracting the data for the current kem
                #print(f"kem_df:\n")
                #print(kem_df)

                
                #print(sig_reused_combined_df)

                # Separating the data into combined dataframes
                sig_first_combined_df = pd.concat([sig_first_combined_df, kem_df.iloc[1:1]])
                sig_reused_combined_df = pd.concat([sig_reused_combined_df, kem_df.iloc[1:2]])

                # sig_first_combined_df.loc[len(sig_first_combined_df)] = kem_df.iloc[0:1]
                # sig_reused_combined_df.loc[len(sig_reused_combined_df)] = kem_df.iloc[1:2]


                #print(sig_first_combined_df)
                print(f"\n\n")
                print(kem_df.iloc[0])
                print(f"\n\n")

            
            # Calculating Averages
            sig_first_average_row = [sig, kem, ""]
            sig_reused_average_row = [sig, kem, "*"]

            # Get average value for each column and append to new row var
            for column in col_headers['pqc_headers']:
                if column in col_headers['pqc_headers'][:3]:
                    continue
                else:
                    sig_first_average_row.append(float(sig_first_combined_df[column].mean()))
                    sig_reused_average_row.append(float(sig_reused_combined_df[column].mean()))
            
            # Append average rows
            sig_avg_df.loc[len(sig_avg_df)] = sig_first_average_row
            sig_avg_df.loc[len(sig_avg_df)] = sig_reused_average_row

        # Output average file
        avg_out_filename = f"tls-handshake-{sig}-avg.csv"
        avg_out_filepath = os.path.join(sig_path, avg_out_filename)
        sig_avg_df.to_csv(avg_out_filepath, index=False)


#------------------------------------------------------------------------------
def gen_classic_avgs(col_headers):
    """ Function for taking in the provided classic TLS handshake
        results and generating an average for all the runs for
        that current machine """

    # Declaring average dataframe
    classic_avg_df = pd.DataFrame(columns=col_headers['classic_headers'])

    # Loop through all ciphersuites
    for cipher in ciphers:

        # Loop through all ECC curves
        for alg in classic_algs:

            # Resetting combined curve dataframe
            curve_first_combined_df = pd.DataFrame(columns=col_headers['classic_headers'])
            curve_reused_combined_df = pd.DataFrame(columns=col_headers['classic_headers'])

            # Looping through all the runs
            for run in range(1, num_runs+1):

                # Setting current run filepath
                current_run_filename = f"classic-results-run-{str(run)}.csv"
                current_run_filepath = os.path.join(dir_paths['classic_handshake_results'], current_run_filename)

                # Reading in current run csv to get metrics
                current_run_df = pd.read_csv(current_run_filepath)

                # Extracting the data for the current curve and ciphersuite
                cipher_df = current_run_df[current_run_df["Ciphersuite"].str.contains(cipher, regex=False)]
                curve_df = cipher_df[cipher_df["Classic Algorithm"].str.contains(alg, regex=False)]

                # Separating the data into combined dataframes
                curve_first_combined_df = pd.concat([curve_first_combined_df, curve_df.iloc[0:1]])
                curve_reused_combined_df = pd.concat([curve_first_combined_df, curve_df.iloc[1:2]])

            # Calculating Averages
            curve_first_combined_row = [cipher, alg, ""]
            curve_reused_combined_row = [cipher, alg, "*"]

            # Get average value for each column and append to new row var
            for column in col_headers['pqc_headers']:
                if column in col_headers['pqc_headers'][:3]:
                    continue
                else:
                    curve_first_combined_row.append(float(curve_first_combined_df[column].mean()))
                    curve_reused_combined_row.append(float(curve_reused_combined_df[column].mean()))
            
            # Append average rows
            classic_avg_df.loc[len(classic_avg_df)] = curve_first_combined_row
            classic_avg_df.loc[len(classic_avg_df)] = curve_reused_combined_row

    # Output average file
    avg_out_filename = f"classic-speed-avg.csv"
    avg_out_filepath = os.path.join(dir_paths['classic_handshake_results'], avg_out_filename)
    classic_avg_df.to_csv(avg_out_filepath, index=False)


#------------------------------------------------------------------------------
def gen_speed_avgs(mach_speed_results_dir):
    """ Function for taking in the provided TLS speed results 
        and generating an average for all the runs for that current machine """

    # Declaring column header variables
    kem_headers = ["Algorithm", "Keygen/s", "Encaps/s", "Decaps/s"]
    sig_headers = ["Algorithm", "Sign", "Verify", "sign/s", "verify/s"]

    # Getting average of sig and kem files
    for index in range(1,3):
        
        # Setting variables based on alg type
        if index == 1:
            headers = kem_headers
            alg_type = "kem"
            temp_alg_filename = f"ssl-speed-kem-1.csv"
            temp_alg_filepath = os.path.join(mach_speed_results_dir, temp_alg_filename)
        else:
            headers = sig_headers
            alg_type = "sig"
            temp_alg_filename = f"ssl-speed-sig-1.csv"
            temp_alg_filepath = os.path.join(mach_speed_results_dir, temp_alg_filename)

        # Setting speed average dataframe
        speed_avg_df = pd.DataFrame(columns=headers)

        # Getting algs
        temp_alg_df = pd.read_csv(temp_alg_filepath)
        algs = temp_alg_df["Algorithm"].to_list()

        # Looping through the algs to get combined average dataframes
        for alg in algs:

            # Setting clean combined alg speed dataframe
            combined_df = pd.DataFrame(columns=headers)

            # Looping through the runs to get averages for alg type
            for run_num in range(1, num_runs+1):

                # Setting filename and path
                current_filename = f"ssl-speed-{alg_type}-{run_num}.csv"
                current_filepath = os.path.join(mach_speed_results_dir, current_filename)

                # Getting speed metics across runs for current alg
                current_run_df = pd.read_csv(current_filepath)
                current_run_df = current_run_df[current_run_df["Algorithm"].str.contains(alg, regex=False)]
                combined_df = pd.concat([combined_df, current_run_df.iloc[0:1]])

            # Get average value for each column and append to new row var
            speed_avg_row = []
            
            for column in headers:
                if column in headers[0]:
                    continue
                else:
                    speed_avg_row.append(float(combined_df[column].mean()))

            # Appending row to main average dateframe
            speed_avg_row.insert(0, alg)
            speed_avg_df.loc[len(speed_avg_df)] = speed_avg_row

        # Exporting average csv file
        speed_avg_filename = f"ssl-speed-{alg_type}-avg.csv"
        speed_avg_filepath = os.path.join(mach_speed_results_dir, speed_avg_filename)
        speed_avg_df.to_csv(speed_avg_filepath, index=False)


#------------------------------------------------------------------------------
#def generate_averages(mach_results_classic_dir, mach_speed_results_dir, in_num_runs, sig_paths):
def generate_averages(passed_dir_paths, passed_num_runs, algs_dict, col_headers):
    """ Main function for controlling the OQS-OpenSSL average
        calculations """

    # Setting global variables
    global num_runs, kem_algs, sig_algs, ciphers, classic_algs, dir_paths
    
    # Setting up script variables
    num_runs = passed_num_runs
    dir_paths = passed_dir_paths
    kem_algs = algs_dict['kem_algs']
    sig_algs = algs_dict['sig_algs']
    ciphers = algs_dict['ciphers']
    classic_algs = algs_dict['classic_algs']

    # Calling average generator functions
    gen_pqc_avgs(col_headers)
    gen_classic_avgs(col_headers)
    # gen_speed_avgs(mach_speed_results_dir)

    # Clearing algorithm lists
    kem_algs.clear()
    sig_algs.clear()
    speed_sig_algs.clear()
    speed_kem_algs.clear()