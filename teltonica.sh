#!/bin/bash

# Check if the script is running with sudo
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run with sudo. Exiting..."
    exit 1
fi

# List of required packages
required_packages=(
    "build-essential"
    "libncurses5-dev"
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
    "patch"
    "autoconf"
    "nodejs"
    "cmake"
    "libffi-dev"
)

# Check if the required packages are installed
echo "Checking installation of required packages..."
for package in "${required_packages[@]}"; do
    dpkg -l | grep -q "$package" || {
        echo "Package $package is not installed. Installing..."
        sudo apt install -y "$package"
    }
done

# Check and install python3-distutils
echo "Checking and installing python3-distutils..."
sudo apt-get install -y python3-distutils

# Check for required files
echo "Checking for required files..."
files_to_check=(
    "ncurses"
    "expat"
    "lz4"
    "zstd"
    "perl-data-dumper"
    "perl-findbin"
    "perl-file-copy"
    "perl-file-compare"
    "perl-thread-queue"
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
    "perl"
    "python2-cleanup"
    "python"
    "python3"
    "python3-distutils"
    "git"
    "file"
    "rsync"
    "which"
    "ldconfig-stub"
    "node"
    "npm"
    "jq"
    "gperf"
    "cmake"
)

# Check for each file
for file in "${files_to_check[@]}"; do
    echo -n "Checking '$file'... "
    if command -v "$file" >/dev/null 2>&1; then
        echo "ok."
    else
        echo "failed. Installing..."
        # If the file is not found, install the corresponding package
        case $file in
            "gperf")
                sudo apt install -y gperf
                ;;
            "cmake")
                sudo apt install -y cmake
                ;;
            *)
                echo "No specific package found for '$file'. Skipping."
                ;;
        esac
    fi
done

# 2. Download the latest SDK from the Teltonika website
echo "Downloading the latest SDK from the Teltonika website..."

SDK_URL=$(curl -s https://wiki.teltonika-networks.com/view/RUTX50_Firmware_Downloads | grep -oP 'https://.*?RUTX_R_GPL.*?tar.gz' | head -n 1)
SDK_FILE=$(basename $SDK_URL)

echo "SDK URL: $SDK_URL"
echo "SDK filename: $SDK_FILE"

# Download the SDK
wget $SDK_URL -O $SDK_FILE

# 3. Extract the SDK and create the rutos-ipq40xx-rutx-sdk folder
echo "Extracting the SDK and creating the rutos-ipq40xx-rutx-sdk folder..."
tar -xzf $SDK_FILE
cd rutos-ipq40xx-rutx-sdk

# 4. Check if 'scripts' folder exists
if [ ! -d "./scripts" ]; then
    echo "'scripts' folder not found! Exiting..."
    exit 1
fi

# 5. Fix permissions
echo "Fixing permissions for the SDK directory..."
sudo chown -R $USER:$USER .
sudo chmod -R 755 .

# 6. Execute the feeds for OpenWRT
echo "Executing the feeds for OpenWRT..."
./scripts/feeds update -a
./scripts/feeds install libffi


echo "The process is complete! You can now continue with the firmware build. You can run 'make' or 'make menuconfig'"

