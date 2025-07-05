#!/bin/bash

# Exit on error
set -e

# Trap cleanup function on exit or interruption
trap cleanup EXIT

# Display help message
function display_help() {
    echo "Usage: $0 [-o OLD_ROOTFS] [-n NEW_ROOTFS] [-s NEW_ROOTFS_SIZE_MB]"
    echo
    echo "Options:"
    echo "  -o OLD_ROOTFS           Path to the old root filesystem (e.g., rootfs.ext2)"
    echo "  -n NEW_ROOTFS           Path to the new root filesystem (e.g., rootfs_large.ext2)"
    echo "  -s NEW_ROOTFS_SIZE_MB   Size of the new root filesystem in MB (e.g., 16384 for 16GB)"
    echo "  -h                      Display this help message"
    exit 0
}

# Cleanup function to unmount and remove temporary directories
function cleanup() {
    sudo umount /mnt/rootfs_old 2>/dev/null || true
    sudo umount /mnt/rootfs_large 2>/dev/null || true
    sudo rmdir /mnt/rootfs_old /mnt/rootfs_large 2>/dev/null || true
}

# Default values
OLD_ROOTFS="rootfs.ext2"
NEW_ROOTFS="rootfs_large.ext2"
NEW_ROOTFS_SIZE_MB=16384  # Default to 16GB

# Parse options
while getopts "o:n:s:h" opt; do
    case ${opt} in
        o) OLD_ROOTFS=${OPTARG} ;;
        n) NEW_ROOTFS=${OPTARG} ;;
        s) NEW_ROOTFS_SIZE_MB=${OPTARG} ;;
        h) display_help ;;
        *) display_help ;;
    esac
done

# Validate inputs
if ! [[ ${NEW_ROOTFS_SIZE_MB} =~ ^[0-9]+$ ]]; then
    echo "Error: NEW_ROOTFS_SIZE_MB must be a positive integer."
    exit 1
fi

if [ ! -f "${OLD_ROOTFS}" ]; then
    echo "Error: OLD_ROOTFS file does not exist."
    exit 1
fi

# Create an empty disk image file of the desired size
fallocate -l ${NEW_ROOTFS_SIZE_MB}M ${NEW_ROOTFS}

# Format the disk image file with ext2 filesystem
mkfs.ext2 ${NEW_ROOTFS}

# Create mount points
sudo mkdir -p /mnt/rootfs_old /mnt/rootfs_large

# Mount the old and new root filesystems
sudo mount -o loop,ro ${OLD_ROOTFS} /mnt/rootfs_old
sudo mount -o loop,rw ${NEW_ROOTFS} /mnt/rootfs_large

# Copy the contents from the old root filesystem to the new one
sudo rsync -aHAX /mnt/rootfs_old/ /mnt/rootfs_large/

# Unmount and clean up is handled by the trap
echo "Created ${NEW_ROOTFS} with a size of ${NEW_ROOTFS_SIZE_MB}MB and copied contents from ${OLD_ROOTFS}"
