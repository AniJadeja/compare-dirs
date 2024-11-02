#!/bin/bash

# Check if a directory path is provided
if [[ -z "$1" ]]; then
  echo "Usage: sudo bash gensha.sh <directory_path>"
  exit 1
fi

# Directory to generate SHA for, stripping trailing slash if any
TARGET_DIR="${1%/}"

# Ask for server name
read -p "Enter the server name: " SERVER_NAME

# Get the directory name to use for the output SHA file
DIR_NAME=$(basename "$TARGET_DIR")
OUTPUT_FILE="$TARGET_DIR/${DIR_NAME}-sha.txt"

# Remove any existing SHA file in the target directory
rm -f "$OUTPUT_FILE"

# Function to generate SHA for a file's content (excluding spaces and indentation)
generate_file_sha() {
  local file="$1"
  sha256sum <(tr -d '[:space:]' < "$file") | awk '{print $1}'
}

# Function to calculate directory SHA while ignoring the output SHA file itself
calculate_dir_sha() {
  local dir="$1"
  find "$dir" -type f ! -name "${DIR_NAME}-sha.txt" -exec sha256sum {} + | sha256sum | awk '{print $1}'
}

# Function to process files in the directory, excluding the output SHA file
process_directory() {
  local dir="$1"

  # Generate SHA for the directory contents as a whole, ignoring the output SHA file
  echo "$SERVER_NAME/$DIR_NAME.shaignore -> $(calculate_dir_sha "$dir")" >> "$OUTPUT_FILE"

  # Process each file in the directory except the output SHA file
  find "$dir" -type f ! -name "${DIR_NAME}-sha.txt" | while read -r file; do
    # Calculate SHA based on file content only, ignoring spaces and indentation
    file_sha=$(generate_file_sha "$file")
    # Write the relative file path with server name prefixed and SHA to the output file
    echo "$SERVER_NAME/${file#$TARGET_DIR/} -> $file_sha" >> "$OUTPUT_FILE"
  done
}

# Process the target directory
process_directory "$TARGET_DIR"

echo "SHA checksums generated in $OUTPUT_FILE"
