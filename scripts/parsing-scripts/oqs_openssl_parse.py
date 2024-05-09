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
from results_averager import OqsOpensslResultAverager

# Declaring global variables
dir_paths = {}
algs_dict = {}
pqc_type_vars = {}
speed_type_vars = {}
speed_sig_algs = []
speed_kem_algs = []
speed_headers = []
col_headers = {}
root_dir = ""
num_runs = 0


#------------------------------------------------------------------------------
def setup_parse_env() :
    """Function for setting up the parsing environment by defining various algorithms, ciphers and column headers"""

    global root_dir, dir_paths, col_headers, algs_dict, pqc_type_vars, speed_type_vars, speed_headers

    # Declaring algs dict that will be used by various methods and functions
    algs_dict = {
        'kem_algs': [], 
        'sig_algs': [],
        "hybrid_kem_algs": [],
        "hybrid_sig_algs": [],
        'classic_algs': ["RSA_2048", "RSA_3072", "RSA_4096", "prime256v1", "secp384r1", "secp521r1"], 
        'ciphers': ["TLS_AES_256_GCM_SHA384", "TLS_CHACHA20_POLY1305_SHA256", "TLS_AES_128_GCM_SHA256"]
    }

    # Declaring column headers dict that will be used by various methods and functions
    col_headers = {
        'pqc_based_headers': ["Signing Algorithm", "KEM Algorithm", "Reused Session ID", "Connections in User Time", "User Time (s)", "Connections Per User Second", "Connections in Real Time", "Real Time (s)"],
        'classic_headers': ["Ciphersuite", "Classic Algorithm", "Reused Session ID", "Connections in User Time", "User Time (s)", "Connections Per User Second", "Connections in Real Time", "Real Time (s)"]

    }

    # Declaring dictionary which will contain the respective keys for alg_dict and dir_paths for PQC-only and PQC-Hybrid results
    pqc_type_vars = {
        "kem_alg_type": ["kem_algs", "hybrid_kem_algs"],
        "sig_alg_type": ["sig_algs", "hybrid_sig_algs"],
        "up_results_path": "",
        "results_type": ["pqc_handshake_results", "hybrid_handshake_results"],
        "type_prefix": ["pqc", "hybrid"],
        "base_type": ["pqc_base_results", "hybrid_base_results"]
    }

    speed_type_vars = {"PQC": "", "Hybrid": ""}

    speed_headers = [
        ["Algorithm", "Keygen", "encaps", "decaps", "Keygen/s", "Encaps/s", "Decaps/s"], 
        ["Algorithm", "Keygen", "Signs", "Verify", "Keygen/s", "sign/s", "verify/s"]
    ]

    # Setting main path vars
    current_dir = os.getcwd()
    root_dir = os.path.dirname(os.path.dirname(current_dir))

    # Creating test results dir paths dict
    dir_paths['root_dir'] = os.path.dirname(os.path.dirname(current_dir))
    dir_paths['results_dir'] = os.path.join(root_dir, "test-data", "results", "oqs-openssl")
    dir_paths['up_results'] = os.path.join(root_dir, "test-data", "up-results", "oqs-openssl")

    # Setting the alg list filename based on version flag
    alg_list_files = {
        "kem_algs": os.path.join(root_dir, "test-data", "alg-lists", "ssl-kem-algs.txt"),
        "sig_algs": os.path.join(root_dir, "test-data", "alg-lists", "ssl-sig-algs.txt"),
        "hybrid_kem_algs": os.path.join(root_dir, "test-data", "alg-lists", "ssl-hybr-kem-algs.txt"),
        "hybrid_sig_algs": os.path.join(root_dir, "test-data", "alg-lists", "ssl-hybr-sig-algs.txt")
    }

    # Pulling algorithm names for alg-lists files and creating relevant alg lists
    for alg_type, filepath in alg_list_files.items():
        with open(filepath, "r") as alg_file:
            for line in alg_file:
                algs_dict[alg_type].append(line.strip())


    # Emptying alg_list_files dict as no longer needed
    alg_list_files = None


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
def pqc_based_processing(current_run):
    """Function for parsing PQC or PQC-Hybrid TLS results based on 
       type passed to function for current run"""

    # Process results for both PQC-only (0) and PQC-Hybrid (1) TLS results
    for type_index in range (0,2):

        """Results Pre-Processing """
        # Declaring dataframe used in pre-processing
        sig_metrics_df = pd.DataFrame(columns=col_headers['pqc_based_headers'])

        # Loop through the sig list to create csv
        for sig in algs_dict[pqc_type_vars["sig_alg_type"][type_index]]:

            # Loop through KEM files signed with current sig
            for kem in algs_dict[pqc_type_vars["kem_alg_type"][type_index]]:

                # Set filename and path
                filename = f"tls-handshake-{current_run}-{sig}-{kem}.txt"
                test_filepath = os.path.join(pqc_type_vars["up_results_path"][type_index], filename)
                
                # Getting session id first use metrics for current kem
                current_row = [kem, ""]
                current_row = get_metrics(current_row, test_filepath, get_reuse_metrics=False)
                current_row.insert(0, sig)

                # Adding session id first use row to dataframe
                new_row_df = pd.DataFrame([current_row], columns=col_headers['pqc_based_headers'])
                sig_metrics_df = pd.concat([sig_metrics_df, new_row_df], ignore_index=True)
                current_row.clear()

                # Getting session id reused metrics for current kem
                current_row = [kem, "*"]
                current_row = get_metrics(current_row, test_filepath, get_reuse_metrics=True)
                current_row.insert(0, sig)

                # Adding session id reused use row to dataframe
                new_row_df = pd.DataFrame([current_row], columns=col_headers['pqc_based_headers'])
                sig_metrics_df = pd.concat([sig_metrics_df, new_row_df], ignore_index=True)
                current_row.clear()

        # Outputting full base PQC TLS metrics for current run
        base_out_filename = f"{pqc_type_vars['type_prefix'][type_index]}-base-results-run-{current_run}.csv"
        output_filepath = os.path.join(dir_paths[pqc_type_vars["base_type"][type_index]], base_out_filename)
        sig_metrics_df.to_csv(output_filepath,index=False)

        """Parse Results"""
        # Setting base results filename and path based on current run
        pqc_base_filename = f"{pqc_type_vars['type_prefix'][type_index]}-base-results-run-{current_run}.csv"
        pqc_base_filepath = os.path.join(dir_paths[pqc_type_vars["base_type"][type_index]], pqc_base_filename)

        # Making storage dir and files for separated sig/kem combo results
        for sig in algs_dict[pqc_type_vars["sig_alg_type"][type_index]]:

            # Set path for sig/kem combo dir
            sig_path = os.path.join(dir_paths[pqc_type_vars["results_type"][type_index]], sig)

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


#------------------------------------------------------------------------------
def classic_based_processing(current_run):
    """ Function for processing results from classic cipher TLS testing"""

    # Setting up-results dir path and creating dataframe used in test processing
    classic_up_results_dir = os.path.join(dir_paths['mach_up_results_dir'], "handshake-results", "classic")
    cipher_metrics_df = pd.DataFrame(columns=col_headers['classic_headers'])

    # Looping through each ciphersuite
    for cipher in algs_dict['ciphers']:

        # Looping through each ecc alg
        for alg in algs_dict['classic_algs']:

            # Set filename and path
            filename = f"tls-handshake-classic-{current_run}-{cipher}-{alg}.txt"
            test_filepath = os.path.join(classic_up_results_dir, filename)
            
            # Getting session id first use metrics for current kem
            current_row = [alg, ""]
            current_row = get_metrics(current_row, test_filepath, get_reuse_metrics=False)
            current_row.insert(0, cipher)

            # Adding session id first use row to dataframe
            new_row_df = pd.DataFrame([current_row], columns=col_headers['classic_headers'])
            cipher_metrics_df = pd.concat([cipher_metrics_df, new_row_df], ignore_index=True)
            current_row.clear()
            
            # Getting session id reused metrics for current kem
            current_row = [alg, "*"]
            current_row = get_metrics(current_row, test_filepath, get_reuse_metrics=True)
            current_row.insert(0, cipher)

            # Adding session id reused use row to dataframe
            new_row_df = pd.DataFrame([current_row], columns=col_headers['classic_headers'])
            cipher_metrics_df = pd.concat([cipher_metrics_df, new_row_df], ignore_index=True)
            current_row.clear()

    # Outputting full base Classic TLS metrics for current run
    cipher_out_filename = f"classic-results-run-{current_run}.csv"
    output_filepath = os.path.join(dir_paths['classic_handshake_results'], cipher_out_filename)
    cipher_metrics_df.to_csv(output_filepath, index=False)

#------------------------------------------------------------------------------
def ssl_speed_drop_last(data_cells):
    """Function for removing unwanted characters from 
        metric values during the ssl-speed parsing"""

    # Loop through values and remove an s chars present in metrics
    for cell_index in range(1, len(data_cells)):
        cell_value = data_cells[cell_index]
        if "s" in cell_value:
            data_cells[cell_index] = data_cells[cell_index].replace('s', '')

    return data_cells


#------------------------------------------------------------------------------
def get_speed_metrics(speed_filepath, alg_type):

    # Declaring vars needed for getting metrics and setting up dataframe with test/alg type headers
    start = False
    data_lists = []
    headers = speed_headers[0] if alg_type == "kem" else speed_headers[1]
    speed_metrics_df = pd.DataFrame(columns=headers)

    # Opening file and extracting
    with open(speed_filepath, "r") as speed_file:

        for line in speed_file:

            # Checking to see if result table has started
            if "keygens/s" in line:
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

        # Removing any s char present in speed metric values for the row
        data_cells = ssl_speed_drop_last(data_cells)

        # Adding new data row to speed metrics data frame
        new_row_df = pd.DataFrame([data_cells], columns=headers)
        speed_metrics_df = pd.concat([speed_metrics_df, new_row_df], ignore_index=True)

    return speed_metrics_df

#------------------------------------------------------------------------------
def speed_processing(current_run):
    """Function for processing openssl speed metrics for both PQC-only and PQC-Hybrid algorithms
       for the current run"""

    # Define alg type list 
    alg_types = ["kem", "sig"]

    # Loop through test types and process up-results for speed metrics
    for test_type, dir_list in dir_paths['speed_types_dirs'].items():

        # Set file prefix depending on test type
        pqc_fileprefix = "ssl-speed" if test_type == "pqc" else "ssl-speed-hybrid"

        # Process both KEM and Sig results for the current test type
        for alg_type in alg_types:

            # Setting up-results filepath and pulling metrics from raw file
            speed_filepath = os.path.join(dir_list[0], f"{pqc_fileprefix}-{alg_type}-{str(current_run)}.txt")
            speed_metrics_df = get_speed_metrics(speed_filepath, alg_type)

            # Outputting speed metrics csv
            output_filepath = os.path.join(dir_list[1], f"{pqc_fileprefix}-{alg_type}-{str(current_run)}.csv")
            speed_metrics_df.to_csv(output_filepath, index=False)


#------------------------------------------------------------------------------
def output_processing():
    """ Function for processing the outputs of the 
        s_time TLS benchmarking tests for the current machine"""
    
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

    # Loop through the runs and call result processing functions
    for current_run in range(1, num_runs+1):
        pqc_based_processing(current_run)
        classic_based_processing(current_run)
        speed_processing(current_run)

#------------------------------------------------------------------------------
def process_tests(num_machines, algs_dict):
    """ Function for controlling the parsing scripts for
        the OQS-OpenSSL up-result files and calling average 
        calculation scripts """
    
    global dir_paths, pqc_type_vars

    # Declare average_gen class instance
    oqs_provider_avg = None
    oqs_provider_avg = OqsOpensslResultAverager(dir_paths, num_runs, algs_dict, pqc_type_vars, col_headers)

    # Looping through the specified number of machines
    for machine in range(1, num_machines+1):

        # Setting machine's results dirs
        dir_paths['mach_results_dir'] = os.path.join(dir_paths['results_dir'], f"machine-{str(machine)}")
        dir_paths['mach_up_results_dir'] = os.path.join(dir_paths['up_results'], f"machine-{str(machine)}")
        dir_paths['mach_handshake_dir']  = os.path.join(dir_paths['results_dir'], f"machine-{str(machine)}", "handshake-results")
        dir_paths['mach_up_speed_dir'] = os.path.join(dir_paths['up_results'], f"machine-{str(machine)}", "speed-results")
        dir_paths['mach_speed_results_dir'] = os.path.join(dir_paths['results_dir'], f"machine-{str(machine)}", "speed-results")
        dir_paths['speed_types_dirs'] = {
            "pqc": [os.path.join(dir_paths['mach_up_speed_dir'], "pqc"), os.path.join(dir_paths['mach_speed_results_dir'])], 
            "hybrid": [os.path.join(dir_paths['mach_up_speed_dir'], "hybrid"), os.path.join(dir_paths['mach_speed_results_dir'])],
        }

        # Setting pqc-var types dictionary so that both PQC-only and PQC-hybrid results can be processed
        pqc_type_vars.update({
           "up_results_path": [
                os.path.join(dir_paths['mach_up_results_dir'], "handshake-results", "pqc"), 
                os.path.join(dir_paths['mach_up_results_dir'], "handshake-results", "hybrid")
            ], 
        })

        # Creating results directory for current machine and handling Machine-ID clashes
        handle_results_dir_creation(machine)

        # Calling processing functions
        output_processing()

        # Calling average calculation function
        oqs_provider_avg.gen_pqc_avgs()
        oqs_provider_avg.gen_classic_avgs()
        oqs_provider_avg.gen_speed_avgs(speed_headers)


#------------------------------------------------------------------------------
def parse_openssl(test_opts):

    # Getting test options and setting test parameter vars
    global num_runs
    num_machines = test_opts[0]
    num_runs = test_opts[1]

    # Setting up script variables
    print(f"\nPreparing to Parse OQS-OpenSSL Results:\n")
    setup_parse_env()

    # Processing the OQS-OpenSSL results
    print("Parsing results... ")
    process_tests(num_machines, algs_dict)