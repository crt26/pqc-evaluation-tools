"""
Copyright (c) 2023-2025 Callum Turino
SPDX-License-Identifier: MIT

Controller script for parsing PQC performance results produced by the Liboqs and OQS-Provider testing tools.
It allows the user to select whether to parse Liboqs, OQS-Provider, or both result sets, and interactively
collects the test parameters (e.g., number of machines and runs) used during benchmarking. The script then 
invokes the appropriate parsing modules and outputs cleaned, formatted CSV files to the results directory 
at the project root.
"""

#-----------------------------------------------------------------------------------------------------------
from liboqs_parse import parse_liboqs
from oqs_provider_parse import parse_oqs_provider
import os
import sys

#-----------------------------------------------------------------------------------------------------------
def setup_base_env():
    """ Function for setting up the global environment variables for the test suite. The function establishes
        the root path by determining the path of the script and recursively moving up the directory tree until
        it finds the .pqc_eval_dir_marker.tmp file. The root path is then returned to the main function. """
    
    # Determine the directory that the script is being executed from and set the marker filename
    script_dir = os.path.dirname(os.path.abspath(__file__))
    current_dir = script_dir
    marker_filename = ".pqc_eval_dir_marker.tmp"

    # Continue moving up the directory tree until the .pqc_eval_dir_marker.tmp file is found
    while True:

        # Check if the .pqc_eval_dir_marker.tmp file is present
        if os.path.isfile(os.path.join(current_dir, marker_filename)):
            root_dir = current_dir
            return root_dir

        # Move up a directory and store the new path
        current_dir = os.path.dirname(current_dir)

        # If the system's root directory is reached and the file is not found, exit the script
        if current_dir == "/":
            print("Root directory path file not present, please ensure the path is correct and try again.")
            sys.exit(1)

#-----------------------------------------------------------------------------------------------------------
def get_test_opts(root_dir):
    """ Helper function for getting the test parameters used in during the automated testing, which includes 
        the number of runs and number of machines tested. """

    # Get the total number of machines tested from the user
    while True:
        try:
            machine_num = int(input("Enter the number of machines tested - "))
            break
        except ValueError:
            print("Invalid Input - Please enter a number!")
    
    # Get the total number of test runs from the user
    while True:
        try:
            total_runs = int(input("Enter the number test runs - "))
            break
        except ValueError:
            print("Invalid Input - Please enter a number!")
    
    test_opts = [machine_num, total_runs, root_dir]
    return test_opts

#-----------------------------------------------------------------------------------------------------------
def main():
    """Main function which controls the parsing scripts for Liboqs and OQS-Provider testing results"""

    # Setup the base environment for the script
    root_dir = setup_base_env()

    # Output the greeting message to the terminal
    print(f"PQC-Evaluation-Tools Results Parsing Tool\n\n")

    # Get the parsing mode from the user
    while True:

        # Output the parsing options to user and store the response
        print("Please select one of the following Parsing options:")
        print("1 - Parse Liboqs results")
        print("2 - Parse OQS-Provider results")
        print("3 - Parse both Liboqs and OQS-Provider results")
        print("4 - Exit")
        user_parse_mode = input("Enter your choice (1-4): ")
        print(f"\n")

        # Determine the parsing mode based on the user response
        if user_parse_mode == '1':

            # Output the selected parsing option
            print("Parsing only Liboqs results selected")

            # Get the test options used for the benchmarking
            print(f"Setting total liboqs machine results\n")
            liboqs_test_opts = get_test_opts(root_dir)

            # Call the parsing script for Liboqs results
            parse_liboqs(liboqs_test_opts)
            break
        
        elif user_parse_mode == '2':

            # Output the selected parsing option
            print("Parsing only OQS-Provider results selected")

            # Get the test options used for the benchmarking
            print(f"Setting total OQS-Provider machine results\n")
            oqs_provider_test_opts = get_test_opts(root_dir)

            # Call the parsing script for OQS-Provider TLS results
            parse_oqs_provider(oqs_provider_test_opts)
            break

        elif user_parse_mode == '3':

            # Output the selected parsing option
            print("Parsing both result sets selected")

            # Get the test options used for the benchmarking
            print(f"Setting total Liboqs machine results\n")
            liboqs_test_opts = get_test_opts(root_dir)

            print(f"\nSetting total OQS-Provider machine results\n")
            oqs_provider_test_opts = get_test_opts(root_dir)
            
            # Parse the Liboqs results
            parse_liboqs(liboqs_test_opts)
            print("\nLiboqs Parsing complete\n")

            # Parse the OQS-Provider Results
            parse_oqs_provider(oqs_provider_test_opts)
            print("\nOQS-Provider Parsing complete\n")
            break

        elif user_parse_mode == '4':
            print("Exiting...")
            break

        else:
            print("Invalid option, please select a valid option value (1-4)")

    # Output the parsing completed message to the terminal
    print(f"\nResults processing complete, parsed results can be found in the results folder at the repo root")

#------------------------------------------------------------------------------
"""Main boiler plate"""
if __name__ == "__main__":
    main()