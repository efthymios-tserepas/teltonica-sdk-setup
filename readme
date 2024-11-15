# Teltonica SDK Setup

This Bash script automates the setup and build process for the Teltonika RUTX SDK, including the installation of required packages and dependencies for building the firmware. The script downloads the latest SDK from the official Teltonika website, extracts it, sets up the necessary tools and dependencies, and prepares the environment for building the firmware.

The script also checks if the necessary tools are installed, installs them if needed, and configures the environment for building the SDK.

## Features

- **Automatic Package Installation:** Ensures that all required packages are installed (e.g., `build-essential`, `git`, `cmake`, `python3-distutils`, and others).
- **SDK Download and Extraction:** Downloads the latest Teltonika SDK from the official website and extracts it to the appropriate directory.
- **Dependencies Handling:** Ensures that all necessary dependencies (e.g., `ncurses`, `expat`, `lz4`, `perl`, etc.) are installed and ready to use.
- **Environment Setup:** Fixes permissions and prepares the environment for building the SDK.
- **OpenWRT Feeds Setup:** Automatically updates and installs the necessary feeds for building the firmware.
- **Permissions Fixing:** Ensures the SDK folder and build environment have the correct permissions to avoid permission issues during the build process.

## Troubleshooting

In case of permission issues or missing dependencies, the script attempts to automatically fix them. If it fails, users will be prompted with the specific error and guidance on how to resolve it manually. Common issues include permission errors and missing package installations.

- For **Ubuntu/Debian-based systems**, it checks and installs required packages using `apt`.
- If there are issues with missing files or dependencies, it will try to download and install them automatically.

## Install

To install and set up the Teltonika SDK, run the following command:

```bash
sudo bash -c "$(curl -o- https://raw.githubusercontent.com/efthymios-tserepas/teltonica-sdk-setup/main/teltonica.sh)"

