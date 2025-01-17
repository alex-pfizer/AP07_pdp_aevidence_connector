#!/bin/sh

## Check if MY_PATH is defined and exists
if [ -z "$MY_PATH" ]; then
    echo "MY_PATH does not exist."
    exit 1
fi

if [ ! -d "$MY_PATH"]; then
    echo "The specified path does not exist: MY_PATH"
    exit 1
fi

## Copy the files from MY_PATH to the container
cp -r "$MY_PATH/"* /usr/local/src/pdp_input