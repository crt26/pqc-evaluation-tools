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
kem_algs = []
sig_algs = []
speed_sig_algs = []
speed_kem_algs = []
system_type = ""
root_dir = ""
num_runs = 0
path_sep = ""

# Declaring classic alg lists
classic_algs = ["RSA:2048", "RSA:3072", "RSA:4096", "prime256v1", "secp384r1", "secp521r1"]
ciphers=["TLS_AES_256_GCM_SHA384", "TLS_CHACHA20_POLY1305_SHA256", "TLS_AES_128_GCM_SHA256"]
ecc_curves=["prime256v1", "secp384r1", "secp521r1"]

# Declaring column headers list    
pqc_headers = ["Signing Algorithm", "KEM Algorithm", "Reused Session ID", "Connections in User Time", "User Time (s)", "Connections Per User Second", "Connections in Real Time", "Real Time (s)"]
classic_headers = ["Ciphersuite", "ECC Algorithm", "Reused Session ID", "Connections in User Time", "User Time (s)", "Connections Per User Second", "Connections in Real Time", "Real Time (s)"]


#------------------------------------------------------------------------------
def get_system_type() :
    """ Function for checking the system type and setting root_dir path """
    global root_dir, system_type, path_sep

    # Checking and storing system type
    if sys.platform == "win32":

        system_type = "win"
        root_dir = r"..\.."
        path_sep = "\\"

    else:
        system_type = "linux"
        current_dir = os.getcwd()
        root_dir = os.path.dirname(os.path.dirname(current_dir))
        path_sep = "/"


#------------------------------------------------------------------------------
def get_algs():
    """ Function for reading in the various algorithms into 
        an array for use within the script """

    # Setting alg filenames
    ssl_sig_alg_file = os.path.join(root_dir, "alg-lists", "ssl-sig-algs.txt")
    ssl_kem_alg_file = os.path.join(root_dir, "alg-lists", "ssl-kem-algs.txt")
    ssl_speed_sig_alg_file = os.path.join(root_dir, "alg-lists", "ssl-speed-sig-algs.txt")
    ssl_speed_kem_alg_file = os.path.join(root_dir, "alg-lists", "ssl-speed-kem-algs.txt")

    # Getting signing algs
    with open(ssl_sig_alg_file, "r") as sig_file:
        for line in sig_file:
            sig_algs.append(line.strip())

    # Getting kem algs
    with open(ssl_kem_alg_file, "r") as kem_file:
        for line in kem_file:
            kem_algs.append(line.strip())

    # Getting speed test sig algs
    with open(ssl_speed_sig_alg_file, "r") as speed_sig_file:
        for line in speed_sig_file:
            speed_sig_algs.append(line.strip())

    # Getting speed test kem algs
    with open(ssl_speed_kem_alg_file, "r") as speed_kem_file:
        for line in speed_kem_file:
            speed_kem_algs.append(line.strip())


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
def output_processing(mach_base_results_dir, mach_up_results_dir, mach_results_classic_dir, sig_paths):
    """ Function for processing the outputs of the 
        s_time TLS benchmarking tests """

    # Setting PQC and Classic up-results dir
    pqc_up_results_dir = os.path.join(mach_up_results_dir, "pqc-tests")
    classic_up_results_dir = os.path.join(mach_up_results_dir, "classic-tests")

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

                # Skipping if Sig and KEM are both classic
                if sig in classic_algs and kem in classic_algs:
                    continue
                else:

                    # Set filename and path
                    sig_name = sig.replace(':', '_')
                    filename = f"tls-speed-{current_run}-{sig_name}-{kem}.txt"
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
        sig_out_filename = f"pqc-base-results-run-{current_run}.csv"
        output_filepath = os.path.join(mach_base_results_dir, sig_out_filename)
        sig_metrics_df.to_csv(output_filepath,index=False)

        """Parse PQC Results"""

        # Setting base results filename and path based on current run
        pqc_base_filename = f"pqc-base-results-run-{current_run}.csv"
        pqc_base_filepath = os.path.join(mach_base_results_dir, pqc_base_filename)

        # Separate signing results 
        for sig_path in sig_paths:

            # Getting current sig from path variable
            sig_split = sig_path.split(path_sep)
            sig_name = sig_split[-1]
            sig = sig_split[-1].replace("_", ":")

            # Reading in current run base results and extracting sig
            base_df = pd.read_csv(pqc_base_filepath)
            current_sig_df = base_df[base_df["Signing Algorithm"].str.contains(sig)]

            # Outputting current sig filtered df to csv
            output_filename = f"tls-speed-{sig_name}-run-{current_run}.csv"
            output_filepath = os.path.join(sig_path, output_filename)
            current_sig_df.to_csv(output_filepath, index=False)

        """Classic Test Result Processing"""

        # Looping through each ciphersuite
        for cipher in ciphers:

            # Looping through each ecc alg
            for curve in ecc_curves:

                # Set filename and path
                filename = f"tls-speed-classic-{current_run}-{cipher}-{curve}.txt"
                test_filepath = os.path.join(classic_up_results_dir, filename)
                
                # Getting session id first use metrics for current kem
                current_row = [curve, ""]
                current_row = get_metrics(current_row, test_filepath, get_reuse_metrics=False)
                current_row.insert(0, cipher)

                # Adding session id first use row to dataframe
                new_row_df = pd.DataFrame([current_row], columns =classic_headers)
                cipher_metrics_df = pd.concat([cipher_metrics_df, new_row_df], ignore_index=True)
                current_row.clear()
                
                # Getting session id reused metrics for current kem
                current_row = [curve, "*"]
                get_reuse_metrics = True
                current_row = get_metrics(current_row, test_filepath, get_reuse_metrics=True)
                current_row.insert(0, cipher)

                # Adding session id reused use row to dataframe
                new_row_df = pd.DataFrame([current_row], columns=classic_headers)
                cipher_metrics_df = pd.concat([cipher_metrics_df, new_row_df], ignore_index=True)
                current_row.clear()

        # Outputting full base Classic TLS metrics for current run
        cipher_out_filename = f"classic-results-run-{current_run}.csv"
        output_filepath = os.path.join(mach_results_classic_dir, cipher_out_filename)
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
def process_tests(num_machines):
    """ Function for controlling the parsing scripts for
        the OQS-OpenSSL up-result files and calling average 
        calculation scripts """

    # Declaring directory variables
    results_dir = os.path.join(root_dir, "results", "openssl")
    up_results_dir = os.path.join(root_dir, "up-results", "openssl")

    # Creating root results dir and removing old
    try:
        os.mkdir(results_dir)
    
    except FileExistsError:
        shutil.rmtree(results_dir)
        os.mkdir(results_dir) 

    # Looping through the specified number of machines
    for machine in range(1, num_machines+1):

        # Setting results path list
        sig_paths = []

        # Setting machine's results dirs
        mach_results_dir = os.path.join(results_dir, f"machine-{str(machine)}")
        mach_up_results_dir = os.path.join(up_results_dir, f"machine-{str(machine)}")
        mach_base_results_dir = os.path.join(results_dir, f"machine-{str(machine)}", "base-results")
        mach_speed_results_dir = os.path.join(results_dir, f"machine-{str(machine)}", "ssl-speed-results")
        mach_results_classic_dir = os.path.join(results_dir, f"machine-{str(machine)}", "classic-ciphers")

        # Creating needed sig output directories for current machine
        for sig in sig_algs:
            try:
                # Making final results directories 
                sig_name = sig.replace(":", "_")
                mach_sig_results_dir = os.path.join(mach_results_dir, sig_name)
                sig_paths.append(mach_sig_results_dir)
                os.makedirs(mach_sig_results_dir)
                
            except FileExistsError:
                shutil.rmtree(mach_sig_results_dir)
                os.makedirs(mach_sig_results_dir)

        # Creating current machines bases results dir
        try:
            os.mkdir(mach_base_results_dir)
        except:
            shutil.rmtree(mach_base_results_dir)
            os.mkdir(mach_base_results_dir)
        
        # Creating current machines ssl-speed results dir
        try:
            os.mkdir(mach_speed_results_dir)
        except:
            shutil.rmtree(mach_speed_results_dir)
            os.mkdir(mach_speed_results_dir)

        # Creating current machines classic results dir
        try:
            os.mkdir(mach_results_classic_dir)
        except:
            shutil(mach_results_classic_dir)
            os.mkdir(mach_results_classic_dir)

        # Calling processing functions
        output_processing(mach_base_results_dir, mach_up_results_dir, mach_results_classic_dir, sig_paths)
        ssl_speed_processing(mach_up_results_dir, mach_speed_results_dir)

        # Calling average calculation function
        generate_averages(mach_results_classic_dir, mach_speed_results_dir, num_runs, sig_paths)


#------------------------------------------------------------------------------
def parse_openssl(test_opts):

    # Getting test options and setting test parameter vars
    global num_runs
    num_machines = test_opts[0]
    num_runs = test_opts[1]

    # Setting up script variables
    print(f"\nPreparing to Parse OQS-OpenSSL Results:\n")
    get_system_type()
    get_algs()

    # Processing the OQS-OpenSSL results
    print("Parsing results... ")
    process_tests(num_machines)