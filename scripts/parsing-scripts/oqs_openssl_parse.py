"""
Copyright (c) 2023 Callum Turino
SPDX-License-Identifier: MIT

This python script will parse the OQS-OpenSSL result files outputted by the bash scripts
into CSV files. Alongside, calling an average generator script to calculate averages
for the results.

"""

#------------------------------------------------------------------------------
import pandas as pd
import os
import shutil
import sys
from oqs_openssl_avg_gen import generate_averages

# Declaring global variables
dir_paths = {}
kem_algs = []
sig_algs = []
speed_sig_algs = []
speed_kem_algs = []
col_headers = {}
root_dir = ""
num_runs = 0

# Declaring classic alg lists
classic_algs = ["RSA_2048", "RSA_3072", "RSA_4096", "prime256v1", "secp384r1", "secp521r1"]
ciphers=["TLS_AES_256_GCM_SHA384", "TLS_CHACHA20_POLY1305_SHA256", "TLS_AES_128_GCM_SHA256"]
#ecc_curves=["prime256v1", "secp384r1", "secp521r1"]

# Declaring column headers list    
pqc_headers = ["Signing Algorithm", "KEM Algorithm", "Reused Session ID", "Connections in User Time", "User Time (s)", "Connections Per User Second", "Connections in Real Time", "Real Time (s)"]
classic_headers = ["Ciphersuite", "Classic Algorithm", "Reused Session ID", "Connections in User Time", "User Time (s)", "Connections Per User Second", "Connections in Real Time", "Real Time (s)"]

#------------------------------------------------------------------------------
def setup_parse_env() :


    global root_dir, kem_algs, sig_algs, dir_paths, col_headers

    # Setting main path vars
    current_dir = os.getcwd()
    root_dir = os.path.dirname(os.path.dirname(current_dir))

    # Creating test results dir paths dict
    dir_paths['root_dir'] = os.path.dirname(os.path.dirname(current_dir))
    dir_paths['results_dir'] = os.path.join(root_dir, "test-data", "results", "oqs-openssl")
    dir_paths['up_results'] = os.path.join(root_dir, "test-data", "up-results", "oqs-openssl")

    # Setting the alg list filename based on version flag
    kem_algs_file = os.path.join(root_dir, "test-data", "alg-lists", "ssl-kem-algs.txt")
    sig_algs_file = os.path.join(root_dir, "test-data", "alg-lists", "ssl-sig-algs.txt")

    # Inserting the kem algs into list for later use
    with open(kem_algs_file, "r") as kem_file:
        for line in kem_file:
            kem_algs.append(line.strip())
    
    # Inserting the digital signature algs into list for later use
    with open(sig_algs_file, "r") as alg_file:
        for line in alg_file:
            sig_algs.append(line.strip())

    algs_dict = {'kem_algs': kem_algs, 'sig_algs': sig_algs, 'classic_algs': classic_algs, 'ciphers': ciphers}
    col_headers = {'pqc_headers': pqc_headers, 'classic_headers': classic_headers}

    return algs_dict



#------------------------------------------------------------------------------
def handle_results_dir_creation(machine_num):
    """Function for handling what the user wants to do with old results"""

    # Checking if there are old parsed results for current Machine-ID and handling clashes 
    if os.path.exists(dir_paths["mach_results_dir"]):

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

                os.makedirs(dir_paths["mach_handshake_dir"])
                os.makedirs(dir_paths["mach_speed_results_dir"])

                break

            elif user_choice == "2":

                # Exiting the script to allow the user to move old results before retrying
                print("Exiting parsing script...")
                exit()

            elif user_choice == "3":

                # Halting script until old results have been moved for current Machine-ID
                while True:
                    input(f"Halting parsing script so old parsed results for Machine-ID ({machine_num}) can be moved, press enter to continue")
                    if os.path.exists(dir_paths["mach_results_dir"]):
                        print(f"Old parsed results for Machine-ID ({machine_num}) still present!!!\n")
                    else:
                        print("Old results have been moved, now continuing with parsing script")
                        os.makedirs(dir_paths["mach_handshake_dir"])
                        os.makedirs(dir_paths["mach_speed_results_dir"])
                        break
                
                break

            else:
                print("Incorrect value, please select (1/2/3)")

    else:

        # No old parsed results for current machine-id present so creating new dirs
        os.makedirs(dir_paths["mach_handshake_dir"])
        os.makedirs(dir_paths["mach_speed_results_dir"])


#------------------------------------------------------------------------------
def get_metrics(current_row, test_filepath, get_reuse_metrics):
    """ Function for pulling the current sig/kem metrics from 
        the OQS-OpenSSL s_time output file """

    # Getting relevant data from the output file
    try:
        with open(test_filepath, "r") as test_file:

            # Flag used to determine metric type
            session_metrics_flag = False

            for line in test_file:

                # Checking line to see if metrics are for session id reused
                if "reuse" in line:
                    session_metrics_flag = True

                # Getting line 1 metrics using keywords
                if "connections" in line and "user" in line:

                    # Checking if metrics is first use or reuse
                    if session_metrics_flag is False and get_reuse_metrics is False:

                        # Store line 1 first use metrics
                        separated_line = line.split()
                        current_row.append(separated_line[0])
                        current_row.append(separated_line[3][:-2])
                        current_row.append(separated_line[4])

                    elif session_metrics_flag is True and get_reuse_metrics is True:

                        # Store line 1 session id reuse metrics
                        separated_line = line.split()
                        current_row.append(separated_line[0])
                        current_row.append(separated_line[3][:-2])
                        current_row.append(separated_line[4])
                
                # Getting line 2 metrics using keywords
                elif "connections" in line and "real" in line:

                    # Checking if metrics is first use or reuse
                    if session_metrics_flag is False and get_reuse_metrics is False:

                        # Store line 2 first use metrics
                        separated_line = line.split()
                        current_row.append(separated_line[0])
                        current_row.append(separated_line[3])
                        break

                    elif session_metrics_flag is True and get_reuse_metrics is True:

                        # Store line 2 session id reuse metrics
                        separated_line = line.split()
                        current_row.append(separated_line[0])
                        current_row.append(separated_line[3])

    except:
        # Outputting file not found error and missing file
        print(f"missing file - {test_filepath}")

        # Creating empty row as placeholder
        for _ in range(1,6):
            current_row.append("")

    return current_row


#------------------------------------------------------------------------------
#def output_processing(mach_base_results_dir, mach_up_results_dir, mach_results_classic_dir, sig_paths):
def output_processing():
    """ Function for processing the outputs of the 
        s_time TLS benchmarking tests """

    # Setting PQC and Classic up-results dir
    pqc_up_results_dir = os.path.join(dir_paths['mach_up_results_dir'], "handshake-results", "pqc")
    classic_up_results_dir = os.path.join(dir_paths['mach_up_results_dir'], "handshake-results", "classic")

    # Setting different results paths for current machine
    dir_paths['pqc_handshake_results'] = os.path.join(dir_paths['mach_handshake_dir'], "pqc")
    dir_paths['classic_handshake_results'] = os.path.join(dir_paths['mach_handshake_dir'], "classic")
    dir_paths['hybrid_handshake_results'] = os.path.join(dir_paths['mach_handshake_dir'], "hybrid")

    dir_paths['pqc_base_results'] = os.path.join(dir_paths['pqc_handshake_results'], "base-results")
    #dir_paths['classic_base_results'] = os.path.join(dir_paths['classic_handshake_results'], "base-results")
    dir_paths['hybrid_base_results'] = os.path.join(dir_paths['hybrid_handshake_results'], "base-results")

    # Making base-results dirs
    os.makedirs(dir_paths['pqc_base_results'])
    os.makedirs(dir_paths['classic_handshake_results'])
    os.makedirs(dir_paths['hybrid_base_results'])

    # Loop through the runs
    for current_run in range(1, num_runs+1):

        # Declaring dataframes
        sig_metrics_df = pd.DataFrame(columns=pqc_headers)
        cipher_metrics_df = pd.DataFrame(columns=classic_headers)

        """ PQC Test Results Pre-Processing """

        # Loop through the sig list to create csv
        for sig in sig_algs:

            # Loop through KEM files signed with current sig
            for kem in kem_algs:

                # Set filename and path
                #sig_name = sig.replace(':', '_')
                filename = f"tls-handshake-{current_run}-{sig}-{kem}.txt"
                test_filepath = os.path.join(pqc_up_results_dir, filename)
                
                # Getting session id first use metrics for current kem
                current_row = [kem, ""]
                get_reuse_metrics = False
                current_row = get_metrics(current_row, test_filepath, get_reuse_metrics)
                current_row.insert(0, sig)

                # Adding session id first use row to dataframe
                new_row_df = pd.DataFrame([current_row], columns =pqc_headers)
                sig_metrics_df = pd.concat([sig_metrics_df, new_row_df], ignore_index=True)
                current_row.clear()

                # Getting session id reused metrics for current kem
                current_row = [kem, "*"]
                get_reuse_metrics = True
                current_row = get_metrics(current_row, test_filepath, get_reuse_metrics)
                current_row.insert(0, sig)

                # Adding session id reused use row to dataframe
                new_row_df = pd.DataFrame([current_row], columns=pqc_headers)
                sig_metrics_df = pd.concat([sig_metrics_df, new_row_df], ignore_index=True)
                current_row.clear()

        # Outputting full base PQC TLS metrics for current run
        base_out_filename = f"pqc-base-results-run-{current_run}.csv"
        output_filepath = os.path.join(dir_paths['pqc_base_results'], base_out_filename)
        sig_metrics_df.to_csv(output_filepath,index=False)

        """Parse PQC Results"""

        # Setting base results filename and path based on current run
        pqc_base_filename = f"pqc-base-results-run-{current_run}.csv"
        pqc_base_filepath = os.path.join(dir_paths['pqc_base_results'], pqc_base_filename)


        # Making storage dir and files for separated sig/kem combo results
        for sig in sig_algs:

            # Set path for sig/kem combo dir
            sig_path = os.path.join(dir_paths['pqc_handshake_results'], sig)

            # Making storage dir for seperated sig/kem combo results if not made
            if not os.path.exists(sig_path):
                os.makedirs(sig_path)
            
            # Reading in current run base results and extracting sig
            base_df = pd.read_csv(pqc_base_filepath)
            current_sig_df = base_df[base_df["Signing Algorithm"].str.contains(sig)]

            # Outputting current sig filtered df to csv
            output_filename = f"tls-handshake-{sig}-run-{current_run}.csv"
            output_filepath = os.path.join(sig_path, output_filename)
            current_sig_df.to_csv(output_filepath, index=False)


        """Classic Test Result Processing"""

        # Looping through each ciphersuite
        for cipher in ciphers:

            # Looping through each ecc alg
            for alg in classic_algs:

                # Set filename and path
                filename = f"tls-handshake-classic-{current_run}-{cipher}-{alg}.txt"
                test_filepath = os.path.join(classic_up_results_dir, filename)
                
                # Getting session id first use metrics for current kem
                current_row = [alg, ""]
                current_row = get_metrics(current_row, test_filepath, get_reuse_metrics=False)
                current_row.insert(0, cipher)

                # Adding session id first use row to dataframe
                new_row_df = pd.DataFrame([current_row], columns =classic_headers)
                cipher_metrics_df = pd.concat([cipher_metrics_df, new_row_df], ignore_index=True)
                current_row.clear()
                
                # Getting session id reused metrics for current kem
                current_row = [alg, "*"]
                get_reuse_metrics = True
                current_row = get_metrics(current_row, test_filepath, get_reuse_metrics=True)
                current_row.insert(0, cipher)

                # Adding session id reused use row to dataframe
                new_row_df = pd.DataFrame([current_row], columns=classic_headers)
                cipher_metrics_df = pd.concat([cipher_metrics_df, new_row_df], ignore_index=True)
                current_row.clear()

        # Outputting full base Classic TLS metrics for current run
        cipher_out_filename = f"classic-results-run-{current_run}.csv"
        output_filepath = os.path.join(dir_paths['classic_handshake_results'], cipher_out_filename)
        cipher_metrics_df.to_csv(output_filepath, index=False)


#------------------------------------------------------------------------------
def ssl_speed_drop_last(data_cells):
    """Function for removing unwanted characters from 
        sig values during the ssl-speed parsing"""
    
    # Convert alg name to list, remove colon and set back to string
    sig_alg_name = data_cells[0]
    alg_name_list = list(sig_alg_name)
    del alg_name_list[-1]
    sig_alg_name = ''.join(alg_name_list)
    data_cells[0] = sig_alg_name

    # Take s character out of sign and verify values
    sign_string = data_cells[1]
    verify_string = data_cells[2]
    sign_list = list(sign_string)
    verify_list = list(verify_string)
    del sign_list[-1]
    del verify_list[-1]
    sign_number = ''.join(sign_list)
    verify_number = ''.join(verify_list)
    data_cells[1] = sign_number
    data_cells[2] = verify_number

    return data_cells


#------------------------------------------------------------------------------
def ssl_speed_processing(mach_up_results_dir, mach_speed_results_dir):
    """Function for parsing OQS-OpenSSL speed up-result files"""

    # Setting speed up-results dir path
    speed_up_results_dir = os.path.join(mach_up_results_dir, "speed-tests")

    # Declaring column headers list
    kem_headers = ["Algorithm", "Keygen/s", "Encaps/s", "Decaps/s"]
    sig_headers = ["Algorithm", "Sign", "Verify", "sign/s", "verify/s"]

    # Loop through the specified number of runs
    for current_run in range(1, num_runs+1):

        # Declaring flag and data list variables
        start = False
        data_lists = []
        alg_type_flags = [False, True] # False is KEM and True is Sig

        # Getting the data for sig and kem
        for alg_type in alg_type_flags:

            # Setting variables based on alg type
            if alg_type == False:
                speed_metrics_df = pd.DataFrame(columns=kem_headers)
                speed_file_name = f"ssl-speed-kem-{str(current_run)}.txt"
                speed_filepath = os.path.join(speed_up_results_dir, speed_file_name)
                algs = speed_kem_algs
                headers = kem_headers
                test_alg_type = "kem"
            
            elif alg_type == True:
                speed_metrics_df = pd.DataFrame(columns=sig_headers)
                speed_file_name = f"ssl-speed-sig-{str(current_run)}.txt"
                speed_filepath = os.path.join(speed_up_results_dir, speed_file_name)
                algs = speed_sig_algs
                headers = sig_headers
                test_alg_type = "sig"

            # Resetting start flag
            start = False

            # Opening file and extracting
            with open(speed_filepath, "r") as speed_file:
                for line in speed_file:

                    # Checking to see if result table has started
                    if "keygen/s" in line:
                        start = True
                        continue
                    elif "sign" in line and "verify" in line:
                        start = True
                        continue

                    # If result table has started extract data
                    if start:
                        data_lists.append(line.strip())
            
            # Appending data onto dataframe
            for data in data_lists:

                # Inserting alg name to row
                data_cells = data.split()

                # Removing colon from sig algs
                if alg_type == True:
                    data_cells = ssl_speed_drop_last(data_cells)

                # Adding new data row to speed metrics data frame
                new_row_df = pd.DataFrame([data_cells], columns=headers)
                speed_metrics_df = pd.concat([speed_metrics_df, new_row_df], ignore_index=True)

            # Outputting speed metrics csv
            speed_out_filename = f"ssl-speed-{test_alg_type}-{current_run}.csv"
            output_filepath = os.path.join(mach_speed_results_dir, speed_out_filename)
            speed_metrics_df.to_csv(output_filepath, index=False)
            data_lists.clear()


#------------------------------------------------------------------------------
def process_tests(num_machines, algs_dict):
    """ Function for controlling the parsing scripts for
        the OQS-OpenSSL up-result files and calling average 
        calculation scripts """
    
    global dir_paths

    # Looping through the specified number of machines
    for machine in range(1, num_machines+1):

        # Setting results path list
        sig_paths = []

        # Setting machine's results dirs
        dir_paths['mach_results_dir'] = os.path.join(dir_paths['results_dir'], f"machine-{str(machine)}")
        dir_paths['mach_up_results_dir'] = os.path.join(dir_paths['up_results'], f"machine-{str(machine)}")
        dir_paths['mach_handshake_dir']  = os.path.join(dir_paths['results_dir'], f"machine-{str(machine)}", "handshake-results")
        dir_paths['mach_speed_results_dir'] = os.path.join(dir_paths['results_dir'], f"machine-{str(machine)}", "speed-results")

        # Creating results directory for current machine and handling Machine-ID clashes
        handle_results_dir_creation(machine)

        # Calling processing functions
        output_processing()
        #ssl_speed_processing(mach_up_results_dir, mach_speed_results_dir)

        # Calling average calculation function
        generate_averages(dir_paths, num_runs, algs_dict, col_headers)
        #generate_averages(mach_results_classic_dir, mach_speed_results_dir, num_runs, sig_paths)


#------------------------------------------------------------------------------
def parse_openssl(test_opts):

    # Getting test options and setting test parameter vars
    global num_runs
    num_machines = test_opts[0]
    num_runs = test_opts[1]

    # Setting up script variables
    print(f"\nPreparing to Parse OQS-OpenSSL Results:\n")
    algs_dict = setup_parse_env()

    # Processing the OQS-OpenSSL results
    print("Parsing results... ")
    process_tests(num_machines, algs_dict)