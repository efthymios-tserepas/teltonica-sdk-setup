#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Define colors
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
NC='\033[0m' # No Color

# Define symbols
CHECK_MARK="[✔]"
CROSS_MARK="[x]"

# Save the original username
ORIGINAL_USER=$(logname)

# Get the HOME directory for the user running the script
USER_HOME=$(eval echo ~$ORIGINAL_USER)

# Initialize progress
TOTAL_STEPS=7
CURRENT_STEP=0
PROGRESS=0

# Function to display the welcome message
display_welcome() {
    # Install figlet if not installed
    if ! command -v figlet >/dev/null 2>&1; then
        echo -e "${YELLOW}Installing 'figlet' for ASCII art...${NC}"
        apt-get install -y figlet >/dev/null 2>&1
    fi

    echo -e "${CYAN}"
    figlet -c -f slant "WELCOME"
    echo -e "${NC}"
    echo -e "${BLUE}Now beginning installation of dependencies for building Teltonika SDK firmware.${NC}"
}

# Function to display progress bar
display_progress_bar() {
    BAR_WIDTH=50
    FILLED_WIDTH=$((PROGRESS * BAR_WIDTH / 100))
    EMPTY_WIDTH=$((BAR_WIDTH - FILLED_WIDTH))
    FILLED_BAR=$(printf "%${FILLED_WIDTH}s" | tr ' ' '#')
    EMPTY_BAR=$(printf "%${EMPTY_WIDTH}s" | tr ' ' '.')
    # Print progress bar on a new line
    printf "${MAGENTA}Progress: [${FILLED_BAR}${EMPTY_BAR}] ${PROGRESS}%%${NC}\n"
}

# Function to update progress
update_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    PROGRESS=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    display_progress_bar
}

# Function to check if the script is running with sudo
check_sudo() {
    echo -n "Checking for sudo privileges... "
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}${CROSS_MARK} This script must be run with sudo. Exiting...${NC}"
        exit 1
    else
        echo -e "${GREEN}${CHECK_MARK} You have sudo privileges.${NC}"
    fi
    update_progress
}

# Function to check for internet connection
check_internet() {
    echo -n "Checking internet connection... "
    if ! ping -c 1 google.com &>/dev/null; then
        echo -e "${RED}${CROSS_MARK} No internet connection. Please check your network settings.${NC}"
        exit 1
    else
        echo -e "${GREEN}${CHECK_MARK} Internet connection is active.${NC}"
    fi
    update_progress
}

# Function to handle script interruption (e.g., Ctrl+C)
trap_ctrlc() {
    echo -e "${RED}\nScript interrupted. Exiting...${NC}"
    exit 1
}
trap 'trap_ctrlc' INT

# Function to check and install libncurses-dev with version control
check_libncurses() {
    echo -n "Checking for libncurses-dev... "
    INSTALLED_VERSION=$(dpkg-query -W -f='${Version}' libncurses-dev 2>/dev/null || echo "none")
    if [ "$INSTALLED_VERSION" = "none" ]; then
        echo -e "${RED}${CROSS_MARK} not installed${NC}"
        echo -e "${YELLOW}Installing libncurses-dev...${NC}"
        apt-get install -y libncurses-dev >/dev/null 2>&1
        echo -e "${GREEN}${CHECK_MARK} libncurses-dev installed.${NC}"
    else
        # Extract major version number
        MAJOR_VERSION=$(echo "$INSTALLED_VERSION" | cut -d'.' -f1)
        if [ "$MAJOR_VERSION" -lt 5 ]; then
            echo -e "${RED}${CROSS_MARK} version $INSTALLED_VERSION is too old${NC}"
            echo -e "${YELLOW}Upgrading libncurses-dev...${NC}"
            apt-get install -y libncurses-dev >/dev/null 2>&1
            echo -e "${GREEN}${CHECK_MARK} libncurses-dev upgraded to latest version.${NC}"
        else
            echo -e "${GREEN}${CHECK_MARK} installed (version $INSTALLED_VERSION)${NC}"
        fi
    fi
}

# Function to install required packages
install_packages() {
    echo "Checking installation of required packages..."

    # List of required packages
    required_packages=(
        "build-essential"
        "gawk"
        "git"
        "gettext"
        "unzip"
        "file"
        "libssl-dev"
        "wget"
        "liblz4-dev"
        "libzstd-dev"
        "make"
        "perl"
        "libperl-dev"
        "patch"
        "autoconf"
        "cmake"
        "libffi-dev"
        "gperf"
        "rsync"
        "jq"
        "curl"
        "libexpat1-dev"
        "python3-distutils-extra"
        "python-is-python3"
        "libtool"
        "libtool-bin"
        "libsemanage-dev"
        "libc6-dev"
        "libgmp-dev"
        "libmpc-dev"
        "libmpfr-dev"
        "libelf-dev"
        "bison"
        "flex"
        "texinfo"
        "zlib1g-dev"
        "lua5.3"
        "liblua5.1-0-dev"
        "luarocks"
        "openjdk-17-jdk"
        "ecj"
        "device-tree-compiler"
        "figlet"  # Added figlet for ASCII art
    )

    # Update package list
    echo -n "Updating package list... "
    apt-get update -qq
    echo -e "${GREEN}${CHECK_MARK}${NC}"

    # Check for missing packages
    missing_packages=()
    for package in "${required_packages[@]}"; do
        if dpkg -s "$package" >/dev/null 2>&1; then
            echo -e "${GREEN}${CHECK_MARK} $package is installed.${NC}"
        else
            echo -e "${RED}${CROSS_MARK} $package is not installed.${NC}"
            missing_packages+=("$package")
        fi
    done

    # Install missing packages
    if [ ${#missing_packages[@]} -ne 0 ]; then
        echo -e "${YELLOW}Installing missing packages...${NC}"
        apt-get install -y "${missing_packages[@]}"
        echo -e "${GREEN}${CHECK_MARK} All missing packages installed.${NC}"
    else
        echo -e "${GREEN}${CHECK_MARK} All required packages are already installed.${NC}"
    fi

    # Check and install libncurses-dev with version control
    check_libncurses

    update_progress
}

# Function to install NodeJS 20.x
install_nodejs() {
    echo -n "Installing NodeJS 20.x... "
    # Remove any existing NodeJS versions
    apt-get remove -y nodejs >/dev/null 2>&1 || true

    # Install NodeJS 20.x from NodeSource
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - >/dev/null 2>&1
    apt-get install -y nodejs >/dev/null 2>&1

    # Verify installation
    NODE_VERSION=$(node -v)
    if [[ "$NODE_VERSION" =~ ^v20\. ]]; then
        echo -e "${GREEN}${CHECK_MARK} NodeJS $NODE_VERSION installed successfully.${NC}"
    else
        echo -e "${RED}${CROSS_MARK} Failed to install NodeJS 20.x. Installed version is $NODE_VERSION.${NC}"
        exit 1
    fi
}

# Function to check and install required commands
install_commands() {
    echo "Checking for required commands..."

    # List of required commands (only actual commands)
    required_commands=(
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
        if command -v "$cmd" >/dev/null 2>&1; then
            echo -e "${GREEN}${CHECK_MARK} $cmd is available.${NC}"
        else
            echo -e "${RED}${CROSS_MARK} $cmd is not available.${NC}"
            echo -e "${YELLOW}Installing $cmd...${NC}"
            # Install the package for the command
            case $cmd in
                "gperf")
                    apt-get install -y gperf >/dev/null 2>&1
                    ;;
                "cmake")
                    apt-get install -y cmake >/dev/null 2>&1
                    ;;
                "curl")
                    apt-get install -y curl >/dev/null 2>&1
                    ;;
                "node")
                    install_nodejs
                    ;;
                "lz4")
                    apt-get install -y liblz4-tool >/dev/null 2>&1
                    ;;
                "perl")
                    apt-get install -y perl >/dev/null 2>&1
                    ;;
                "python3")
                    apt-get install -y python3 >/dev/null 2>&1
                    ;;
                "bison")
                    apt-get install -y bison >/dev/null 2>&1
                    ;;
                "flex")
                    apt-get install -y flex >/dev/null 2>&1
                    ;;
                "autoconf")
                    apt-get install -y autoconf >/dev/null 2>&1
                    ;;
                "automake")
                    apt-get install -y automake >/dev/null 2>&1
                    ;;
                "libtool")
                    apt-get install -y libtool libtool-bin >/dev/null 2>&1
                    ;;
                # Add cases for other commands as needed
                *)
                    echo -e "${YELLOW}No specific package found for '$cmd'. Skipping.${NC}"
                    ;;
            esac
            echo -e "${GREEN}${CHECK_MARK} $cmd installed.${NC}"
        fi
    done
    update_progress
}

# Function to configure Git for longer timeouts and retries
configure_git() {
    echo -n "Configuring Git... "
    # Increase the timeout to avoid interruptions
    git config --global http.lowSpeedLimit 1
    git config --global http.lowSpeedTime 60
    # Allow Git to retry in case of failure
    git config --global fetch.retries 3
    # Buffer = 100MB
    git config --global http.postBuffer 104857600
    echo -e "${GREEN}${CHECK_MARK}${NC}"
    update_progress
}

# Function to download the SDK and perform additional setup
download_sdk() {
    echo "Downloading the latest SDK from the Teltonika website..."

    # Fetch the SDK URL
    echo -n "Fetching SDK URL... "
    SDK_URL=$(curl -s https://wiki.teltonika-networks.com/view/RUTX50_Firmware_Downloads | grep -oP 'https://.*?RUTX_R_GPL.*?tar.gz' | head -n 1)
    if [ -z "$SDK_URL" ]; then
        echo -e "${RED}${CROSS_MARK} SDK URL not found. Exiting...${NC}"
        exit 1
    else
        echo -e "${GREEN}${CHECK_MARK}${NC}"
    fi

    SDK_FILE=$(basename "$SDK_URL")

    echo "SDK URL: $SDK_URL"
    echo "SDK filename: $SDK_FILE"

    # Download the SDK to the user's home directory
    DOWNLOAD_PATH="$USER_HOME/$SDK_FILE"

    if [ -f "$DOWNLOAD_PATH" ]; then
        echo -e "${YELLOW}SDK file already exists. Skipping download.${NC}"
    else
        echo -n "Downloading SDK... "
        if ! wget "$SDK_URL" -O "$DOWNLOAD_PATH" >/dev/null 2>&1; then
            echo -e "${RED}${CROSS_MARK} Failed to download the SDK. Exiting...${NC}"
            exit 1
        else
            echo -e "${GREEN}${CHECK_MARK}${NC}"
        fi
    fi

    # Verify the downloaded file
    echo -n "Verifying SDK file... "
    if ! tar -tzf "$DOWNLOAD_PATH" &>/dev/null; then
        echo -e "${RED}${CROSS_MARK} The downloaded SDK file is corrupted. Deleting it and retrying...${NC}"
        rm -f "$DOWNLOAD_PATH"
        if ! wget "$SDK_URL" -O "$DOWNLOAD_PATH" >/dev/null 2>&1; then
            echo -e "${RED}${CROSS_MARK} Failed to download the SDK. Exiting...${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}${CHECK_MARK}${NC}"
    fi

    # Extract the SDK
    echo -n "Extracting the SDK... "
    tar -xzf "$DOWNLOAD_PATH" -C "$USER_HOME"
    echo -e "${GREEN}${CHECK_MARK}${NC}"

    # Change to the SDK directory and set SDK_PATH
    SDK_DIR=$(tar -tzf "$DOWNLOAD_PATH" | head -1 | cut -f1 -d"/")
    if [ -d "$USER_HOME/$SDK_DIR" ]; then
        SDK_PATH="$USER_HOME/$SDK_DIR"
        cd "$SDK_PATH"
    else
        echo -e "${RED}${CROSS_MARK} SDK directory not found! Exiting...${NC}"
        exit 1
    fi

    # Fix permissions
    echo -n "Fixing permissions... "
    chown -R "$ORIGINAL_USER:$ORIGINAL_USER" "$SDK_PATH"
    chmod -R 755 "$SDK_PATH"
    echo -e "${GREEN}${CHECK_MARK}${NC}"

    # Create necessary directories and symbolic links after extracting SDK
    if [ ! -d "$SDK_PATH/staging_dir/target-arm_cortex-a7+neon-vfpv4_musl_eabi/usr/include/" ]; then
        echo -n "Creating required directories... "
        mkdir -p "$SDK_PATH/staging_dir/target-arm_cortex-a7+neon-vfpv4_musl_eabi/usr/include/"
        echo -e "${GREEN}${CHECK_MARK}${NC}"
    fi

    # Check for the symbolic link and create it if it doesn't exist
    if [ ! -L "$SDK_PATH/staging_dir/target-arm_cortex-a7+neon-vfpv4_musl_eabi/usr/include/lua5.1-deb-multiarch.h" ]; then
        echo -n "Creating symlink for lua5.1-deb-multiarch.h... "
        ln -s /usr/include/x86_64-linux-gnu/lua5.1-deb-multiarch.h "$SDK_PATH/staging_dir/target-arm_cortex-a7+neon-vfpv4_musl_eabi/usr/include/"
        echo -e "${GREEN}${CHECK_MARK}${NC}"
    else
        echo -e "${YELLOW}Symlink for lua5.1-deb-multiarch.h already exists.${NC}"
    fi

    # Check if 'scripts' folder exists
    if [ ! -d "$SDK_PATH/scripts" ]; then
        echo -e "${RED}${CROSS_MARK} 'scripts' folder not found! Exiting...${NC}"
        exit 1
    fi

    update_progress
}

# Function to update feeds and install packages
update_feeds_and_install() {
    echo -e "${BLUE}Updating feeds and installing packages...${NC}"
    echo -e "${YELLOW}Please be patient, this process may take a while.${NC}"

    # Ensure we are in the SDK directory
    cd "$SDK_PATH"

    # Update feeds
    echo -n "Updating feeds... "
    ./scripts/feeds update -a >/dev/null 2>&1
    echo -e "${GREEN}${CHECK_MARK}${NC}"

    # Install specific packages via feeds
    echo -n "Installing packages via feeds... "
    ./scripts/feeds install libffi >/dev/null 2>&1
    ./scripts/feeds install libnetfilter-acct >/dev/null 2>&1
    echo -e "${GREEN}${CHECK_MARK}${NC}"

    # Prepare ccache
    echo "Preparing ccache..."
    mkdir -p "$SDK_PATH/tools/ccache"
    cd "$SDK_PATH/tools/ccache"
    wget https://github.com/ccache/ccache/releases/download/v4.9.1/ccache-4.9.1.tar.gz >/dev/null 2>&1

    # Create Makefile for ccache
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

    cd "$SDK_PATH"  # Return to the SDK directory

    # Prepare b43-tools
    echo "Preparing b43-tools..."
    mkdir -p "$SDK_PATH/tools/b43-tools"
    cd "$SDK_PATH/tools/b43-tools"

    if [ -d ".git" ]; then
        echo -n "Updating b43-tools repository... "
        git pull >/dev/null 2>&1
        echo -e "${GREEN}${CHECK_MARK}${NC}"
    else
        echo -n "Cloning b43-tools repository... "
        git clone https://github.com/mbuesch/b43-tools.git . >/dev/null 2>&1
        echo -e "${GREEN}${CHECK_MARK}${NC}"
    fi

    # Create Makefile for b43-tools
    cat <<EOF > Makefile
# tools/b43-tools/Makefile
include \$(TOPDIR)/rules.mk

PKG_NAME:=b43-tools
PKG_VERSION:=latest
PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/mbuesch/b43-tools.git
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

    cd "$SDK_PATH"  # Return to the SDK directory

    # Fix permissions after modifications
    echo -n "Fixing permissions after modifications... "
    chown -R "$ORIGINAL_USER:$ORIGINAL_USER" "$SDK_PATH"
    chmod -R 755 "$SDK_PATH"
    echo -e "${GREEN}${CHECK_MARK}${NC}"

    echo "The SDK is prepared. You can now run 'make menuconfig' to configure your build."
    echo "Please run 'make menuconfig' and enable the required packages and tools."
    echo "The process is complete! You can now continue with the firmware build."
    echo "Run 'make menuconfig' to configure your build options."

    update_progress
}

# Function to display usage instructions
usage() {
    echo "Usage: sudo $0"
    exit 0
}

# Main execution
main() {
    display_welcome

    # Check for help flag
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        usage
    fi

    check_sudo
    check_internet
    install_packages
    install_commands
    configure_git
    download_sdk
    update_feeds_and_install

    echo -e "${GREEN}\nThe setup is complete!${NC}"
    echo "Please run 'make menuconfig' inside the SDK directory to configure your build options or 'make' for default build."
}

# Start script execution and log output
# Log output to setup_log.txt
exec > >(tee -i setup_log.txt)
exec 2>&1

main "$@"
