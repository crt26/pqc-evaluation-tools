"""
Copyright (c) 2025 Callum Turino
SPDX-License-Identifier: MIT

This is a utility script which is used to get the algorithms which are supported by the Liboqs library and the OQS-Provider library.
The script will output the algorithms to a text file which can be used by the benchmarking and parsing scripts to determine which algorithms to
test and parse. The main purpose of the script is to be called from the main setup.sh script and be passed an argument which dictates which the install type
so it knows what algorithms are required to be outputted to the text files. The script can also be ran manually if required.

The accepted arguments are:
    - 1 (Liboqs only)
    - 2 (Liboqs and OQS-Provider)
    - 3 (OQS-Provider only)
    - 4 (OQS-Provider ALGORITHMS.md parsing)

"""

#-----------------------------------------------------------------------------------------------------------
import os
import subprocess
import sys

# Set the root directory path variable
root_dir = ""

# Set the path to the liboqs build directory and the openssl path
liboqs_build_dir = ""
openssl_path = ""
openssl_lib_dir = ""
oqs_provider_src_dir = ""

#-----------------------------------------------------------------------------------------------------------
def output_help_message():
    """ # Helper function for outputting the help message to the user when called or when incorrect arguments are passed """

    # Output the supported options and their usage to the user
    print("get_algorithms.py [options]")
    print("\nOptions:")
    print("1        Get the algorithms supported by the Liboqs library")
    print("2        Get the algorithms supported by the Liboqs library and the OQS-Provider library")
    print("3        Get the algorithms supported by the OQS-Provider library")
    print("4        Parse the ALGORITHMS.md file of the OQS-Provider library to get the total number of algorithms supported")
    print("--help   Output the help message to the user")

#-----------------------------------------------------------------------------------------------------------
def setup_base_env():
    """ Function for setting up the basic global variables for the test suite. This includes setting the root directory
        and the global library paths for the test suite. The function establishes the root path by determining the path of the script and 
        using this, determines the root directory of the project """

    global root_dir, liboqs_build_dir, openssl_path, openssl_lib_dir, oqs_provider_src_dir

    # Get the script dir location, set current directory, and set the marker filename
    script_dir = os.path.dirname(os.path.abspath(__file__))
    current_dir = script_dir
    marker_filename = ".pqc_eval_dir_marker.tmp"

    # Loop until the project's root directory is found or the system root directory is reached
    while True:

        # Check if the marker file is present in the current directory and break if found
        marker_path = os.path.join(current_dir, marker_filename)

        if os.path.isfile(marker_path):
            root_dir = current_dir
            break

        # Move up one directory and check again for 
        current_dir = os.path.dirname(current_dir)

        # If the root directory is reached and the file is not found, exit the script
        if current_dir == "/":
            print("Root directory path file not present, please ensure the path is correct and try again.")
            sys.exit(1)

    # Set the path to the liboqs build directory and the openssl path
    liboqs_build_dir = os.path.join(root_dir, "lib", "liboqs", "build", "tests")
    openssl_path = os.path.join(root_dir, "lib", "openssl_3.4")
    openssl_lib_dir = ""

    # Check which OpenSSL lib directory to use depending on the system
    if os.path.isdir(os.path.join(openssl_path, "lib64")):
        openssl_lib_dir = os.path.join(openssl_path, "lib64")

    else:
        openssl_lib_dir= os.path.join(openssl_path, "lib")

    # Export the path to the OpenSSL library directory
    old_ld_library_path = os.environ.get('LD_LIBRARY_PATH', '')
    new_ld_library_path = f"{openssl_lib_dir}:{old_ld_library_path}"
    os.environ['LD_LIBRARY_PATH'] = new_ld_library_path

    # Set the path to the ALGORITHMS.md file
    oqs_provider_src_dir = os.path.join(root_dir, "tmp", "oqs-provider-source")

    # Ensure that there are no previous list files present (mainly for if this script is ran manually, setup.sh will handle this)
    alg_list_dir = os.path.join(root_dir, "test-data", "alg-lists")

    if os.path.isdir(alg_list_dir):
        for file in os.listdir(alg_list_dir):
            os.remove(os.path.join(alg_list_dir, file))
    else:
        os.mkdir(alg_list_dir)

#-----------------------------------------------------------------------------------------------------------
def write_to_file(alg_list, file_name):
    """ Helper function to write the algorithms to a specified text file. The function 
        takes the algorithm list and filename as arguments """

    # Write the algorithms to the specified text file
    with open(file_name, "w") as f:
        for alg in alg_list:
            f.write(f"{alg}\n")

#-----------------------------------------------------------------------------------------------------------
def liboqs_extract_algs(output_str):
    """ Helper function to extract the algorithms from the output string of the liboqs test binaries """

    # Determine the index of where the algorithms start in the output string
    alg_start_index = output_str.find("algname:") + len("algname:")
    
    # Use the index to get the string of algorithms
    alg_str = output_str[alg_start_index:].strip()
    
    # Create a list of the algorithms from the string and remove commas
    algs = alg_str.split(", ")
    
    return algs

#-----------------------------------------------------------------------------------------------------------
def get_liboqs_algs():
    """ Function to get the algorithms supported by the Liboqs library. The function will run the test
        binaries with no arguments to trigger the help output which will contain the algorithms supported """

    # Set the test_bins and output directory for algorithm lists
    test_bins = [f"{liboqs_build_dir}/test_kem", f"{liboqs_build_dir}/test_sig"]
    output_dir = os.path.join(root_dir, "test-data", "alg-lists")

    # Loop through the different test type binaries
    for bin in test_bins:

        # Check if the test binary exists before running
        if os.path.isfile(bin):

            try:
                # Run relevant test binary and capture the output
                process = subprocess.Popen(bin, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
                stdout, stderr = process.communicate()

                # Extract the algorithms from the stderr
                algs = liboqs_extract_algs(stderr)

                # Set the output filename for the current algorithm type
                if "kem" in bin:
                    alg_list_file = os.path.join(output_dir, "kem-algs.txt")
                else:
                    alg_list_file = os.path.join(output_dir, "sig-algs.txt")
                
                # Write out the algorithms to the list file
                write_to_file(algs, alg_list_file)

            except Exception as e:
                print(f"An error occurred: {e}")
            
        else:
            print(f"Test binary '{bin}' not found.")
            return

#-----------------------------------------------------------------------------------------------------------
def oqs_provider_extract_algs(output_str):
    """ Helper function to extract the algorithms from the output string of the OpenSSL binary. The binary is passed 
        the algorithm type and the OQS-Provider flags so that it prints out the algorithms supported for that type in OQS-Provider """

    # Set the lists used for the PQC and Hybrid-PQC algorithms
    algs = []
    hybrid_algs = []

    # Pre-format the output string to remove newlines and split into a list
    pre_algs = output_str.split("\n")
    pre_algs = pre_algs[:-1]

    # Loop through the pre-formatted algorithms and add to the appropriate list
    for alg in pre_algs:
        
        # Format the algorithm string to have only the algorithm name
        alg = alg.strip()
        alg = alg.split(" @ ")[0]

        # Determine if the is a hybrid algorithm or not and add to the appropriate list
        hybrid_prefix = alg.split("_")
        
        if len(hybrid_prefix) > 1:
            hybrid_algs.append(alg.strip())

        else:
            algs.append(alg.strip())

    return algs, hybrid_algs

#-----------------------------------------------------------------------------------------------------------
def get_tls_pqc_algs():
    """ Function to get the PQC and Hybrid-PQC algorithms supported by 
        the OQS-Provider library for the TLS benchmarking """

    # Set required path variables and algorithm categories
    openssl_bin = os.path.join(openssl_path, "bin","openssl")
    output_dir = os.path.join(root_dir, "test-data", "alg-lists")
    alg_cats = ["kem", "signature"]

    # Loop through the different algorithm types and get the algorithms supported
    for alg_type in alg_cats:

        # Run the openssl binary with the required flags to get the algorithms supported and capture the output
        process = subprocess.Popen(
            [openssl_bin, "list", f"-{alg_type}-algorithms", "-provider", "oqsprovider"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=True
        )
        stdout, stderr = process.communicate()

        # Extract the PQC and Hybrid-PQC algorithms from the output string
        algs, hybrid_algs = oqs_provider_extract_algs(stdout)

        # Set the various output filenames depending on the current algorithm type
        if alg_type == "kem":
            alg_list_file = os.path.join(output_dir, "tls-kem-algs.txt")
            speed_list_file = os.path.join(output_dir, "tls-speed-kem-algs.txt")
            hybrid_alg_list_file = os.path.join(output_dir, "tls-hybr-kem-algs.txt")
        
        else:
            alg_list_file = os.path.join(output_dir, "tls-sig-algs.txt")
            speed_list_file = os.path.join(output_dir, "tls-speed-sig-algs.txt")
            hybrid_alg_list_file = os.path.join(output_dir, "tls-hybr-sig-algs.txt")

        # Write out the algorithms to the list file
        write_to_file(algs, alg_list_file)
        write_to_file(hybrid_algs, hybrid_alg_list_file)
        write_to_file(algs, speed_list_file)

#-----------------------------------------------------------------------------------------------------------
def set_tls_classic_algs():
    """ Function to set the classic algorithm lists for the TLS benchmarking. The classic algorithms are not subject 
        to change, so they can be set in the script and then outputted to text files for the benchmarking and parsing scripts """

    # Set the classic algorithms for the TLS benchmarking
    classic_kems = ["prime256v1", "secp384r1", "secp521r1"]
    classic_sigs = ["RSA_2048", "RSA_3072", "RSA_4096", "prime256v1", "secp384r1", "secp521r1"]

    # Set the output directory and text file names
    output_dir = os.path.join(root_dir, "test-data", "alg-lists")
    kem_list_file = os.path.join(output_dir, "classic-tls-kem-algs.txt")
    sig_list_file = os.path.join(output_dir, "classic-tls-sig-algs.txt")
    
    # Write out the classic algorithms to the list files
    write_to_file(classic_kems, kem_list_file)
    write_to_file(classic_sigs, sig_list_file)

#-----------------------------------------------------------------------------------------------------------
def parse_oqs_provider_algorithms_md():
    """ Function for parsing the ALGORITHMS.md file of the OQS-Provider library to extract the total number of algorithms supported
        This is only called when all algorithms are selected to be enabled by the main setup.sh script, as the OpenSSL speed.c source
        file needs to be altered so that a larger number of algorithms can be supported. This function will return the total number of algorithms
        supported by the OQS-Provider library and if parsing fails returns -1 to indicate that the hardcoded high value should be set in the speed.c file """

    # Set the filepaths for the ALGORITHMS.md file and declare main_algs list
    algs_md_filepath = os.path.join(oqs_provider_src_dir, "ALGORITHMS.md")
    main_algs = []

    # Set the in_table to its default value
    in_table = False

    # Try to open the ALGORITHMS.md file and extract the algorithms from the table
    try:

        # Ensure that the file is present
        if not os.path.isfile(algs_md_filepath):
            raise FileNotFoundError()
                
        # Open the ALGORITHMS.md file and extract the number of algorithms supported
        with open (algs_md_filepath, "r", encoding='utf-8') as file:
            for line in file:

                # Determine if the script is currently in the table of algorithms
                if "<!--- OQS_TEMPLATE_FRAGMENT_IDS_START -->" in line:
                    in_table = True
                    continue
                
                elif "<!--- OQS_TEMPLATE_FRAGMENT_IDS_END -->" in line:
                    break
                
                # If in the table extract the algorithm names
                if in_table:

                    # Only extract the algorithms if not in the first lines of the table
                    if "Algorithm" in line or "--" in line:
                        continue

                    else:

                        # Extract the algorithm name from the row and store it in the main_algs list
                        row = line.split("|")
                        del row[0]
                        main_algs.append(row[0].strip())

        # Check that the table was found and the algorithm names were extracted
        if not main_algs:
            raise Exception("No algorithms found in the table")

    except FileNotFoundError:
        print(f"File not found: {algs_md_filepath}")
        sys.exit(1)

    except Exception as e:
        print(f"Failed to parse processing file structure: {e}")
        sys.exit(1)

    # Print out the number of algorithms supported by the OQS-Provider library and exit successfully
    print(f"Total number of Algorithms: {len(main_algs)}")
    sys.exit(0)
    
#-----------------------------------------------------------------------------------------------------------
def main():
    """ Main function for controlling the utility script. The function will determine which algorithms 
        are required based on the argument passed to the script """
    
    # Check if the help flag was passed before continuing
    if "--help" in sys.argv:
        output_help_message()
        sys.exit(0)

    # Ensure a valid argument was passed to the utility script
    if len(sys.argv) == 2:

        # Set up the base environment for the utility script
        setup_base_env()

        # Determine which algorithm lists are required based on the argument passed and create them
        if sys.argv[1] == "1":
            get_liboqs_algs()

        elif sys.argv[1] == "2":
            get_liboqs_algs()
            get_tls_pqc_algs()
            set_tls_classic_algs()

        elif sys.argv[1] == "3":
            get_tls_pqc_algs()
            set_tls_classic_algs()

        elif sys.argv[1] == "4":
            parse_oqs_provider_algorithms_md()

        else:
            print(f"\nInvalid argument has been passed to this utility script, please check the code of the setup.sh script, or if you are running this script manually, ensure you are passing the correct argument")
            print("Required arguments are: 1 (Liboqs only), 2 (liboqs and OQS-Provider), or 3(OQS-Provider only)")
            print(f"\nArgument passed - ", sys.argv[1])
            sys.exit(1)
    
    else:
        print("Invalid number of arguments passed to the utility script, please check the code of the setup.sh script, or if you are running this script manually, ensure you are passing the correct number of arguments")
        sys.exit(1)

#------------------------------------------------------------------------------
"""Main boiler plate"""
if __name__ == "__main__":
    main()