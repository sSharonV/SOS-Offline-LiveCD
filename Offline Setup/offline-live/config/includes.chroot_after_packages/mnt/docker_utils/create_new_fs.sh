#!/bin/sh

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <path_to_save_dockerfs_file> <size_in_megabits> (Mb)"
    exit 1
fi

# Arguments
dockerfs_path=$1
size_in_megabits=$2

# Convert Megabits to bits
size_in_bits=$((size_in_megabits * 1024 * 1024))

# Unmount docker.fs
systemctl stop docker
umount /var/lib/docker

# Create a file of the specified size
echo "Creating a file of size $size_in_bits bits[Mb] at $dockerfs_path"
dd if=/dev/zero of="$dockerfs_path" bs=1 count=1 seek="$size_in_bits"

# Format the file as ext4 filesystem
echo "Formatting the file as ext4 filesystem"
mkfs.ext4 "$dockerfs_path"

# Confirm the creation and formatting
if [ $? -eq 0 ]; then
    echo "File $dockerfs_path created and formatted as ext4 successfully."
    mount /var/lib/docker
    echo "docker.fs mounted successfully."
    systemctl start docker
    echo "docker service successfully updated with docker.fs of size $size_in_bits [Mb]"
else
    echo "Failed to create and format the file."
    exit 1
fi
