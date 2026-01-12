#!/bin/bash

# Check for sudo privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "This script requires sudo privileges."
    echo "Please run the script as root or use sudo."
    exit 1
fi

# Output
echo "## Delete Linux Kernels ##"
echo ""

# Determine current kernel
CURRENT_KERNEL=$(uname -r)

# List and sort all installed kernels
KERNELS=($(dpkg --list | grep linux-image | awk '{print $2}' | grep -v "$CURRENT_KERNEL" | sort -Vr))

# Check if any kernels were found
if [ ${#KERNELS[@]} -eq 0 ]; then
    echo "No additional kernels found to remove."
    exit 0
fi

# Listing
echo "The following kernels were found:"
for (( i=0; i<${#KERNELS[@]}; i++ )); do
 echo ${KERNELS[$i]}
done

echo "---"

# Check if there are more than 3 kernels
if [ ${#KERNELS[@]} -le 3 ]; then
    echo "Only ${#KERNELS[@]} kernels are installed. Nothing will be deleted."
    exit 0
fi

# Delete all kernels except the three most recent ones
for (( i=3; i<${#KERNELS[@]}; i++ )); do
    KERNEL_TO_REMOVE="${KERNELS[$i]}"
    echo "Deleting kernel: $KERNEL_TO_REMOVE"
    if ! sudo apt purge -y "$KERNEL_TO_REMOVE"; then
        echo "Failed to remove kernel: $KERNEL_TO_REMOVE"
        exit 1
    fi

    # Delete corresponding headers
    HEADERS_TO_REMOVE=$(dpkg --list | grep linux-headers | awk '{print $2}' | grep "${KERNEL_TO_REMOVE#linux-image-}")
    if [ -n "$HEADERS_TO_REMOVE" ]; then
        echo "Deleting headers: $HEADERS_TO_REMOVE"
        if ! sudo apt purge -y "$HEADERS_TO_REMOVE"; then
            echo "Failed to remove headers: $HEADERS_TO_REMOVE"
            exit 1
        fi
    fi
done

echo "---"

# Update GRUB
echo "Updating GRUB..."
if ! sudo update-grub; then
    echo "Failed to update GRUB"
    exit 1
fi

# Clean up unnecessary packages
echo "Cleaning up unnecessary packages..."
if ! sudo apt autoremove -y; then
    echo "Failed to clean up unnecessary packages"
    exit 1
fi

echo ""

echo "Done. Please reboot the system to apply the changes."
