#!/bin/sh

# Check if the environment variable MOUNT_PATH is set
if [ -z "$MOUNT_PATH" ]; then
  echo "MOUNT_PATH environment variable is not set. Please set it to the host directory to mount."
  exit 1
fi

# Check if the custom directory is mounted
if [ -d "$MOUNT_PATH" ]; then
  # Copy files from the mounted custom directory to the container directories
  cp -r "$MOUNT_PATH"/* /usr/local/src/pdp_input
  echo "Files have been successfully copied from $MOUNT_PATH"
# else
#   echo "Custom directory not mounted. Please check the path used in $MOUNT_PATH."
fi

# Run the R script
Rscript /usr/local/src/myscripts/test.R

# Execute any additional commands passed to the container
exec "$@"