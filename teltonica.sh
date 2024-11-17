#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Save the original username
ORIGINAL_USER=$(logname)

# Function to check if the script is running with sudo
check_sudo() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "This script must be run with sudo. Exiting..."
        exit 1
    fi
}

# Function to check for internet connection
check_internet() {
    if ! ping -c 1 google.com &>/dev/null; then
        echo "No internet connection. Please check your network settings."
        exit 1
    fi
}

# Function to handle script interruption (e.g., Ctrl+C)
trap_ctrlc() {
    echo "Script interrupted."
    exit 1
}
trap 'trap_ctrlc' INT

# Function to install required packages
install_packages() {
    # List of required packages
    required_packages=(
        "build-essential"
        "libncurses-dev"
        "gawk"
        "git"
        "gettext"
        "unzip"
        "file"
        "libssl-dev"
        "wget"
        "libncursesw5-dev"
        "liblz4-dev"
        "libzstd-dev"
        "make"
        "perl"
        "libperl-dev"               # Added libperl-dev
        "patch"
        "autoconf"
        "cmake"
        "libffi-dev"
        "gperf"
        "rsync"
        "jq"
        "curl"
        "libexpat1-dev"            # Expat library
        "python3-distutils-extra"  # Python3 Distutils module
        "python-is-python3"        # Symlink 'python' to 'python3' if needed
        "libtool"                  # Added libtool
        "libtool-bin"              # Added libtool-bin
        "libsemanage-dev"          # Added libsemanage-dev
        "libc6-dev"                # Added libc6-dev
        "libgmp-dev"               # Added libgmp-dev
        "libmpc-dev"               # Added libmpc-dev
        "libmpfr-dev"              # Added libmpfr-dev
        "libelf-dev"               # Added libelf-dev
        "bison"                    # Added bison
        "flex"                     # Added flex
    )

    # Update package list
    echo "Updating package list..."
    apt-get update

    # Check for missing packages
    echo "Checking installation of required packages..."
    missing_packages=()
    for package in "${required_packages[@]}"; do
        if ! dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q "install ok installed"; then
            missing_packages+=("$package")
        fi
    done

    # Install missing packages
    if [ ${#missing_packages[@]} -ne 0 ]; then
        echo "Installing missing packages: ${missing_packages[@]}"
        apt-get install -y "${missing_packages[@]}"
    else
        echo "All required packages are already installed."
    fi
}

# Function to install NodeJS 20.x
install_nodejs() {
    echo "Installing NodeJS 20.x..."

    # Remove any existing NodeJS versions
    apt-get remove -y nodejs || true

    # Install NodeJS 20.x from NodeSource
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs

    # Verify installation
    NODE_VERSION=$(node -v)
    if [[ "$NODE_VERSION" =~ ^v20\. ]]; then
        echo "NodeJS $NODE_VERSION installed successfully."
    else
        echo "Failed to install NodeJS 20.x. Installed version is $NODE_VERSION."
        exit 1
    fi
}

# Function to check and install required commands
install_commands() {
    # List of required commands
    required_commands=(
        "ncurses"
        "expat"
        "lz4"
        "zstd"
        "perl"
        "tar"
        "find"
        "bash"
        "xargs"
        "patch"
        "diff"
        "cp"
        "seq"
        "awk"
        "grep"
        "egrep"
        "getopt"
        "stat"
        "unzip"
        "bzip2"
        "wget"
        "python3"
        "git"
        "file"
        "rsync"
        "which"
        "ldconfig"
        "node"
        "jq"
        "gperf"
        "cmake"
        "curl"
        "bison"
        "flex"
        "autoconf"
        "automake"
        "libtool"
    )

    # Install missing commands
    for cmd in "${required_commands[@]}"; do
        echo -n "Checking '$cmd'... "
        if command -v "$cmd" >/dev/null 2>&1; then
            echo "ok."
        else
            echo "not found. Installing..."
            case $cmd in
                "gperf")
                    apt-get install -y gperf
                    ;;
                "cmake")
                    apt-get install -y cmake
                    ;;
                "curl")
                    apt-get install -y curl
                    ;;
                "node")
                    install_nodejs
                    ;;
                "ncurses")
                    apt-get install -y libncurses-dev libncursesw5-dev
                    ;;
                "expat")
                    apt-get install -y libexpat1-dev
                    ;;
                "lz4")
                    apt-get install -y liblz4-tool
                    ;;
                "perl")
                    apt-get install -y perl
                    ;;
                "python3")
                    apt-get install -y python3
                    ;;
                "bison")
                    apt-get install -y bison
                    ;;
                "flex")
                    apt-get install -y flex
                    ;;
                "autoconf")
                    apt-get install -y autoconf
                    ;;
                "automake")
                    apt-get install -y automake
                    ;;
                "libtool")
                    apt-get install -y libtool libtool-bin
                    ;;
                *)
                    echo "No specific package found for '$cmd'. Skipping."
                    ;;
            esac
        fi
    done  # Προστέθηκε το 'done' εδώ
}

# Function to configure Git for longer timeouts and retries
configure_git() {
    echo "Configuring Git to allow longer timeouts and retries..."

    # Increase the timeout to avoid interruptions
    git config --global http.lowSpeedLimit 0
    git config --global http.lowSpeedTime 999999

    # Allow Git to retry in case of failure
    git config --global fetch.retries 5
    git config --global http.postBuffer 524288000  # 500MB buffer for Git
}

# Function to download the SDK and perform additional setup
download_sdk() {
    echo "Downloading the latest SDK from the Teltonika website..."

    # Fetch the SDK URL
    SDK_URL=$(curl -s https://wiki.teltonika-networks.com/view/RUTX50_Firmware_Downloads | grep -oP 'https://.*?RUTX_R_GPL.*?tar.gz' | head -n 1)

    # Verify SDK URL
    if [ -z "$SDK_URL" ]; then
        echo "SDK URL not found. Exiting..."
        exit 1
    fi

    SDK_FILE=$(basename "$SDK_URL")

    echo "SDK URL: $SDK_URL"
    echo "SDK filename: $SDK_FILE"

    # Download the SDK if not already downloaded
    if [ -f "$SDK_FILE" ]; then
        echo "SDK file already exists. Skipping download."
    else
        if ! wget "$SDK_URL" -O "$SDK_FILE"; then
            echo "Failed to download the SDK. Exiting..."
            exit 1
        fi
    fi

    # Extract the SDK directory name from the tarball
    SDK_DIR=$(tar -tzf "$SDK_FILE" | head -1 | cut -f1 -d"/")

    # Extract the SDK
    echo "Extracting the SDK..."
    tar -xzf "$SDK_FILE"

    # Change to the SDK directory
    if [ -d "$SDK_DIR" ]; then
        cd "$SDK_DIR"
    else
        echo "SDK directory not found! Exiting..."
        exit 1
    fi

    # Fix permissions
    echo "Fixing permissions for the SDK directory..."
    chown -R "$ORIGINAL_USER:$ORIGINAL_USER" .
    chmod -R 755 .

    # Check if 'scripts' folder exists
    if [ ! -d "./scripts" ]; then
        echo "'scripts' folder not found! Exiting..."
        exit 1
    fi

    # Skip adding additional feeds to avoid duplicates
    echo "Skipping addition of external feeds."

    # Execute the feeds for OpenWrt
    echo "Executing the feeds for OpenWrt..."
    ./scripts/feeds update -a
    ./scripts/feeds install libffi lrexlib
    ./scripts/feeds install libtool libiconv expat libsemanage
    ./scripts/feeds install -a

    # Additional steps for ccache
    echo "Creating folder for ccache and downloading the package..."
    mkdir -p tools/ccache
    cd tools/ccache
    wget https://github.com/ccache/ccache/releases/download/v4.9.1/ccache-4.9.1.tar.gz

    echo "Creating the Makefile for ccache..."
    cat <<EOF > Makefile
# tools/ccache/Makefile
include \$(TOPDIR)/rules.mk

PKG_NAME:=ccache
PKG_VERSION:=4.9.1
PKG_SOURCE_URL:=https://github.com/ccache/ccache/releases/download/v\$(PKG_VERSION)
PKG_SOURCE:=\$(PKG_NAME)-\$(PKG_VERSION).tar.gz
PKG_HASH:=12834ecaaaf2db069dda1d1d991f91c19e3274cc04a471af5b64195def17e90f

include \$(INCLUDE_DIR)/package.mk

define Package/ccache
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Compiler cache
endef

define Build/Configure
  \$(call Build/Configure/Default)
endef

define Package/ccache/install
  \$(INSTALL_DIR) \$(1)/usr/bin
  \$(INSTALL_BIN) \$(PKG_BUILD_DIR)/ccache \$(1)/usr/bin/
endef

\$(eval \$(call BuildPackage,ccache))
EOF

    cd ../..  # Return to the SDK root directory

    # Additional steps for b43-tools
    echo "Creating folder for b43-tools and downloading the package..."
    mkdir -p tools/b43-tools
    cd tools/b43-tools

    if [ -d ".git" ]; then
        echo "Repository already exists. Updating it."
        git pull
    else
        echo "Cloning b43-tools repository..."
        git clone https://github.com/mbuesch/b43-tools.git .
    fi

    # Proceed to create the Makefile
    echo "Creating the Makefile for b43-tools..."
    cat <<EOF > Makefile
# tools/b43-tools/Makefile
include \$(TOPDIR)/rules.mk

PKG_NAME:=b43-tools
PKG_VERSION:=latest
PKG_SOURCE_URL:=https://github.com/mbuesch/b43-tools.git
PKG_SOURCE_PROTO:=git
PKG_SOURCE_VERSION:=HEAD

include \$(INCLUDE_DIR)/package.mk

define Package/b43-tools
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=B43 Wireless Tools
endef

define Build/Configure
  \$(call Build/Configure/Default)
endef

define Package/b43-tools/install
  \$(INSTALL_DIR) \$(1)/usr/bin
  \$(INSTALL_BIN) \$(PKG_BUILD_DIR)/utils/* \$(1)/usr/bin/
endef

\$(eval \$(call BuildPackage,b43-tools))
EOF

    cd ../..  # Return to the SDK root directory
}

# Function to display usage instructions
usage() {
    echo "Usage: sudo $0"
    exit 0
}

# Main execution
main() {
    # Check for help flag
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        usage
    fi

    # Check if running with sudo
    check_sudo

    # Check internet connection
    check_internet

    # Install required packages
    install_packages

    # Install required commands
    install_commands

    # Configure Git
    configure_git

    # Download and prepare the SDK
    download_sdk

    echo "The process is complete! You can now continue with the firmware build. You can run 'make' or 'make menuconfig'"
}

# Start script execution and log output
# Log output to setup_log.txt
exec > >(tee -i setup_log.txt)
exec 2>&1

echo "Starting the setup for Teltonika RUTX50 firmware build environment..."

main "$@"
