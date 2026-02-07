#!/bin/bash

DRY_RUN=false
if [ "$1" = "--dry-run" ]; then
    DRY_RUN=true
fi

if [ "$DRY_RUN" = false ]; then
    if [ "$(id -u)" -ne 0 ]; then
        echo "This script requires sudo privileges."
        echo "Please run the script as root or use sudo."
        exit 1
    fi
fi

echo "## Delete Linux Kernels ##"
echo ""

CURRENT_KERNEL=$(uname -r)
KERNELS=($(dpkg --list | grep linux-image | awk '{print $2}' | grep -v "$CURRENT_KERNEL" | sort -Vr))

if [ ${#KERNELS[@]} -eq 0 ]; then
    echo "No additional kernels found to remove."
    exit 0
fi

echo "The following kernels were found:"
for kernel in "${KERNELS[@]}"; do
    echo "$kernel"
done

echo "---"

if [ ${#KERNELS[@]} -le 3 ]; then
    echo "Only ${#KERNELS[@]} kernels are installed. Nothing will be deleted."
    exit 0
fi

for (( i=3; i<${#KERNELS[@]}; i++ )); do
    KERNEL_TO_REMOVE="${KERNELS[$i]}"
    if [ "$DRY_RUN" = true ]; then
        echo "[DRY RUN] Would delete kernel: $KERNEL_TO_REMOVE"
    else
        echo "Deleting kernel: $KERNEL_TO_REMOVE"
        if ! apt purge -y "$KERNEL_TO_REMOVE"; then
            echo "Failed to remove kernel: $KERNEL_TO_REMOVE"
            exit 1
        fi
    fi

    HEADERS_TO_REMOVE=$(dpkg --list | grep linux-headers | awk '{print $2}' | grep "${KERNEL_TO_REMOVE#linux-image-}")
    if [ -n "$HEADERS_TO_REMOVE" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "[DRY RUN] Would delete headers: $HEADERS_TO_REMOVE"
        else
            echo "Deleting headers: $HEADERS_TO_REMOVE"
            if ! apt purge -y "$HEADERS_TO_REMOVE"; then
                echo "Failed to remove headers: $HEADERS_TO_REMOVE"
                exit 1
            fi
        fi
    fi
done

echo "---"

if [ "$DRY_RUN" = false ]; then
    echo "Updating GRUB..."
    if ! update-grub; then
        echo "Failed to update GRUB"
        exit 1
    fi

    echo "Cleaning up unnecessary packages..."
    if ! apt autoremove -y; then
        echo "Failed to clean up unnecessary packages"
        exit 1
    fi
fi

echo ""

if [ "$DRY_RUN" = true ]; then
    echo "Dry run complete. No changes were made."
else
echo "Done. Please reboot the system to apply the changes."
fi
