"""
Copyright (c) 2023-2026 Callum Turino
SPDX-License-Identifier: MIT

Library-specific configuration for the parsing system. This module defines per-library
metadata (such as raw-result filename prefixes) consumed by the parsing scripts so that
adding a new PQC benchmark backend only requires plugging a new entry into the dict
below, rather than editing the parser itself.

The parsing scripts treat the keys of LIBRARY_PREFIXES as the authoritative list of
supported libraries; the SUPPORTED_LIBRARIES list is provided for convenience.
"""

# Mapping of library identifier (as accepted by the --library CLI flag) to the
# per-library filename conventions used across the test pipeline. Future libraries
# (e.g., wolfSSL, CIRCL) add their entries here.
#
# Per-library keys:
#   kem_speed / sig_speed   - filename prefix of raw speed-result CSVs, run number appended
#   kem_algs_file / sig_algs_file - basename of the algorithm-list file under
#                                   test_data/alg_lists/ (full filename including .txt)
LIBRARY_PREFIXES = {
    "liboqs": {
        "kem_speed": "test_kem_speed_",
        "sig_speed": "test_sig_speed_",
        "kem_algs_file": "kem_algs_liboqs.txt",
        "sig_algs_file": "sig_algs_liboqs.txt",
    },
}

# Ordered list of supported library identifiers. Derived from LIBRARY_PREFIXES so
# the two cannot drift.
SUPPORTED_LIBRARIES = list(LIBRARY_PREFIXES.keys())
