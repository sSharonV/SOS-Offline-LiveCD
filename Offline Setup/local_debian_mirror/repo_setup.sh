#!/bin/bash

LOCAL_MIRROR_FOLDER="local_debian_mirror"

# Directory containing the .deb files
DEB_DIR="dists/bookworm/main/binary-amd64"

# Output directory for the repository
REPO_DIR="$DEB_DIR/../.."

rename_process() {
	# Loop through files in the directory
	for FILE in "$DEB_DIR"/*; do
	    # Check if the file name contains "%"
	    if echo "$FILE" | grep -q "%"; then
		# Create new file name by replacing "%" with "."
		NEW_FILE=$(echo "$FILE" | sed 's/%/./g')
		
		# Rename the file
		mv "$FILE" "$NEW_FILE"
		
		# Check if the rename was successful
		if [ $? -eq 0 ]; then
		    echo "Renamed '$FILE' to '$NEW_FILE'"
		else
		    echo "Failed to rename '$FILE'"
		fi
	    fi
	done

	echo "Renaming process completed."
}

# This script needs to run from LOCAL_MIRROR_FOLDER
check_directory() {
	CUR_DIR=$PWD
	BASE_DIR=$(basename "$CUR_DIR")

	if [ "$BASE_DIR" = $LOCAL_MIRROR_FOLDER ]; then
		echo "Creating repo-tree"
		create_directories
	else
		echo "The current directory needs to be in the folder $LOCAL_MIRROR_FOLDER. Try again..."
	exit 1
	fi
}

handle_metadata() {
 if [ -f "$PWD/dists/bookworm/main/binary-amd64/Packages" ]; then
    echo "Removing existing Packages file..."
    rm "$PWD/dists/bookworm/main/binary-amd64/Packages"
  fi

  if [ -f "$PWD/dists/bookworm/Release" ]; then
    echo "Removing existing Release file..."
    rm "$PWD/dists/bookworm/Release"
  fi
}

# Function to create necessary directories
create_directories() {
	mkdir -p dists/bookworm/main/binary-amd64
}

repo_setup() {
	check_directory

	# Pause the script to allow the user to copy .deb packages
	echo "Please copy your .deb packages to the binary-amd64 folder and press Enter to continue."
	read unused variable	

	# Some tweaks to make it work for us	
	rename_process
	handle_metadata

	# Generate Packages file
	if ! dpkg-scanpackages "$DEB_DIR" /dev/null > "$PWD/$DEB_DIR/Packages"; then
	    echo "Failed to generate Packages file."
	    exit 1
	fi

	# Generate Release file
	RELEASE_FILE="$PWD/$REPO_DIR/Release"
	echo "Hash: SHA256" >> "$RELEASE_FILE" || { echo "Failed to write to Release file."; exit 1; }
	echo " " >> "$RELEASE_FILE" || { echo "Failed to write to Release file."; exit 1; }
	echo "Origin: YourRepoName" >> "$RELEASE_FILE" || { echo "Failed to write to Release file."; exit 1; }
	echo "Label: YourRepoLabel" >> "$RELEASE_FILE" || { echo "Failed to write to Release file."; exit 1; }
	echo "Suite: bookworm" >> "$RELEASE_FILE" || { echo "Failed to write to Release file."; exit 1; }
	echo "Version: 1.0" >> "$RELEASE_FILE" || { echo "Failed to write to Release file."; exit 1; }
	echo "Codename: bookworm" >> "$RELEASE_FILE" || { echo "Failed to write to Release file."; exit 1; }
	echo "Architecture: amd64" >> "$RELEASE_FILE" || { echo "Failed to write to Release file."; exit 1; }
	echo "Components: main" >> "$RELEASE_FILE" || { echo "Failed to write to Release file."; exit 1; }
	echo "Description: Your repository description" >> "$RELEASE_FILE" || { echo "Failed to write to Release file."; exit 1; }
	echo "SHA256:" >> "$RELEASE_FILE" || { echo "Failed to write to Release file."; exit 1; }
	echo " "$(sha256sum "$PWD/$DEB_DIR/Packages" | cut -d ' ' -f 1)" "$(stat -c %s "$PWD/$DEB_DIR/Packages")" main/binary-amd64/Packages" >> "$RELEASE_FILE" || { echo "Failed to write to Release file."; exit 1; }

	echo "Repository files generated successfully."
	exit 0
}

repo_setup
