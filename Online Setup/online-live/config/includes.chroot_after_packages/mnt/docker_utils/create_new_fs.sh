#!/bin/sh

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <path_to_save_dockerfs_file> <size_in_megabits> (Mb)"
    exit 1
fi

# Arguments
DOCKER_FS=$1
SIZE_MB=$2

# Convert Megabits to bits
SIZE_BITS=$((SIZE_MB * 1024 * 1024))

# Unmount docker.fs
systemctl stop docker
umount /var/lib/docker

# Create a file of the specified size
echo "Creating a file of size $SIZE_BITS [Mb] at $DOCKER_FS"
dd if=/dev/zero of="$DOCKER_FS" bs=1 count=1 seek="$SIZE_BITS"

# Format the file as ext4 filesystem
echo "Formatting the file as ext4 filesystem"
mkfs.ext4 "$DOCKER_FS"

# Confirm the creation and formatting
if [ $? -eq 0 ]; then
    echo "File $DOCKER_FS created and formatted as ext4 successfully."
    mount /var/lib/docker
    echo "docker.fs mounted successfully."
    systemctl start docker
    echo "docker service successfully updated with docker.fs of size $SIZE_BITS [Mb]"
else
    echo "Failed to create and format the file."
    exit 1
fi
