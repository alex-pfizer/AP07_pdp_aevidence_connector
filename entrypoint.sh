# #!/bin/sh

# # Print the current directory and its contents
# echo "Current directory: $(pwd)"
# echo "Contents of /usr/local/src/input_pdp:"
# ls -la /usr/local/src/input_pdp

# # Check if the directory exists
# if [ -d "/usr/local/src/input_pdp" ]; then
#     echo "/usr/local/src/input_pdp exists."
# else
#     echo "/usr/local/src/input_pdp does not exist."
# fi

# # Copy the custom directory to the desired location
# cp -r /usr/local/src/input_pdp/* /usr/local/scr/myscripts

# # Execute the command passed to the container
# exec "$@"

#!/bin/sh

# Check if the host directory is mounted
if [ -d "/mnt/hostdir" ]; then
  # Copy files from the mounted host directory to the container directories
  cp -r /mnt/hostdir/* /usr/local/src/pdp_input
else
  echo "Host directory not mounted. Please mount the host directory to /mnt/hostdir."
fi

# Execute any additional commands passed to the container
exec "$@"