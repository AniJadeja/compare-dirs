#!/bin/bash

# Check if two files are provided
if [[ $# -lt 2 ]]; then
  echo "Usage: $0 [-v|-d|-s] <sha_file_1> <sha_file_2>"
  exit 1
fi

# Parse optional flags
VERBOSE=0
DIFFERENCES_ONLY=0
SIMPLE_COMPARE=0

while getopts "vds" option; do
  case $option in
    v) VERBOSE=1 ;;
    d) DIFFERENCES_ONLY=1 ;;
    s) SIMPLE_COMPARE=1 ;;
  esac
done

shift $((OPTIND-1))
SHA_FILE_1="$1"
SHA_FILE_2="$2"

# Read both SHA files into associative arrays, normalizing paths by stripping "AWS/" or "Contabo/"
# Now skipping the first line using 'tail -n +2'
declare -A sha_map_1 sha_map_2

while IFS=' -> ' read -r path sha; do
  normalized_path="${path#AWS/}"
  normalized_path="${normalized_path#Contabo/}"
  sha_map_1["$normalized_path"]="$sha"
done < <(tail -n +2 "$SHA_FILE_1")

while IFS=' -> ' read -r path sha; do
  normalized_path="${path#AWS/}"
  normalized_path="${normalized_path#Contabo/}"
  sha_map_2["$normalized_path"]="$sha"
done < <(tail -n +2 "$SHA_FILE_2")

# Function to compare and display results
compare_shas() {
  local path="$1"
  local sha1="${sha_map_1[$path]}"
  local sha2="${sha_map_2[$path]}"

  if [[ "$sha1" == "$sha2" ]]; then
    if [[ "$VERBOSE" -eq 1 ]]; then
      echo -e "\e[42;97mMATCH\e[0m: $path"
    fi
  else
    if [[ "$DIFFERENCES_ONLY" -eq 1 || "$VERBOSE" -eq 1 ]]; then
      echo -e "\e[41;97mNO_MATCH\e[0m: $path"
    fi
  fi
}

# Run simple comparison if -s flag is provided or no flag is given
if [[ "$SIMPLE_COMPARE" -eq 1 || ( "$VERBOSE" -eq 0 && "$DIFFERENCES_ONLY" -eq 0 ) ]]; then
  if [[ "${sha_map_1["api.shaignore"]}" == "${sha_map_2["api.shaignore"]}" ]]; then
    echo -e "\n      ___  ______ _____ _____  \n" \
            "    / _ \\|  ____|  __ \\_   _| \n" \
            "   | | | | |__  | |  | || |   \n" \
            "   | | | |  __| | |  | || |   \n" \
            "   | |_| | |____| |__| || |_  \n" \
            "    \\___/|______|_____/_____| \n" \
            "      All directories match!  \n"
  else
    echo -e "\n\e[41;97m MISMATCH IN DIRECTORIES \e[0m\n"
  fi
  exit 0
fi

# Comparison flag to check if there are any missing files
missing_in_second_file=0

# Compare SHAs for each path in sha_map_1
for path in "${!sha_map_1[@]}"; do
  if [[ -n "${sha_map_2[$path]}" ]]; then
    compare_shas "$path"
  else
    [[ "$DIFFERENCES_ONLY" -eq 1 || "$VERBOSE" -eq 1 ]] && {
      echo -e "\e[41;97mMISSING IN AWS\e[0m: $path"
      missing_in_second_file=1
    }
  fi
done

# Check for paths that exist in sha_map_2 but not in sha_map_1
for path in "${!sha_map_2[@]}"; do
  if [[ -z "${sha_map_1[$path]}" ]]; then
    [[ "$DIFFERENCES_ONLY" -eq 1 || "$VERBOSE" -eq 1 ]] && {
      echo -e "\e[41;97mMISSING IN CONTABO\e[0m: $path"
      missing_in_second_file=1
    }
  fi
done

# If any files were missing, suppress the NO_MATCH output
if [[ $missing_in_second_file -eq 0 && "$DIFFERENCES_ONLY" -eq 1 ]]; then
  echo -e "\e[42;97mAll files match!\e[0m"
fi
