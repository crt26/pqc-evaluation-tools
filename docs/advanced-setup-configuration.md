# Advanced Setup Configurations
This document outlines additional configuration options available when running the `setup.sh` script. The main setup supports the follow configurations when called:

- Safe Setup

- Manually Adjusting OpenSSL's speed Tool Hardcoded Limits

## Safe Setup
If you encounter compatibility issues with the latest versions of the OQS libraries, you can use **Safe Setup mode**, which installs the last known working versions tested with this repository.

To enable the safe setup option, follow the insulation process steps as normal, but when calling the `setup.sh` script, call it with the `--safe-setup` flag:

```
./setup.sh --safe-setup
```

This will clone the last tested versions of the OQS libraries rather than the version present in the main branch. Please refer to the **Supported Hardware and Software** section in the main `README` file for a list of the latest tested versions of the dependency libraries.

## Adjusting OpenSSL speed Tool Hardcoded Limits
When enabling all disabled digital signature algorithms during the OQS-Provider setup, the number of registered algorithms can exceed OpenSSL's internal limits. This causes the OpenSSL `s_speed` benchmarking tool to fail due to hardcoded values (`MAX_KEM_NUM` and `MAX_SIG_NUM`) in its source code.

By default, the main setup script will attempt to detect and patch these values automatically in the `s_speed` tool's source code. However, if you wish to manually set a custom value (or if auto-patching fails), you can use the following flag:

```
./setup.sh --set-speed-new-value=[integer]
```

Replace [integer] with the desired value to override both `MAX_KEM_NUM` and `MAX_SIG_NUM` values in the OpenSSL source before compilation.

For further details on this issue and future plans to address the problem, please refer to this [git issue](https://github.com/crt26/pqc-evaluation-tools/issues/25) on the repositories page.