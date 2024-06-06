#!/bin/sh

set -e

SOURCE_MNT="/mnt" # For your choice
DEST_MNT="/mnt" # Dissect default

docker run -it --rm \
	--mount type=bind,src=/mnt,target=/mnt,readonly \
	ghcr.io/fox-it/dissect