# SHA Generation and Comparison Tools

This repository contains two Bash scripts for generating and comparing SHA checksums across different servers. These tools are particularly useful for ensuring file integrity and identifying differences between directory structures on different servers.

## Scripts Overview

1. `gensha.sh` - Generates SHA checksums for files in a directory
2. `comparesha.sh` - Compares SHA checksums between two servers

## gensha.sh

### Purpose
This script generates SHA-256 checksums for all files in a specified directory, creating a comprehensive manifest of file contents.

### Usage
```bash
sudo bash gensha.sh <directory_path>
```

### Features
- Generates SHA checksums while ignoring whitespace and indentation
- Creates a manifest file named `<directory_name>-sha.txt`
- Prefixes file paths with server name for easy identification
- Includes a directory-level checksum (.shaignore) for quick comparisons

### Output Format
The script generates a file with the following format:
```
SERVER_NAME/directory_name.shaignore -> <directory_sha>
SERVER_NAME/path/to/file1 -> <file1_sha>
SERVER_NAME/path/to/file2 -> <file2_sha>
```

## comparesha.sh

### Purpose
This script compares SHA checksums between two manifest files, typically generated from different servers.

### Usage
```bash
./comparesha.sh [-v|-d|-s] <sha_file_1> <sha_file_2>
```

### Options
- `-v` (Verbose): Shows all comparisons, including matches
- `-d` (Differences): Shows only differences and missing files
- `-s` (Simple): Only compares directory-level checksums

### Features
- Skips the first line of each file (header)
- Normalizes paths by removing "AWS/" or "Contabo/" prefixes
- Color-coded output for easy identification
- Multiple comparison modes for different use cases

### Output Types
1. **Match**: 
   ```
   MATCH: path/to/file (only shown in verbose mode)
   ```

2. **No Match**: 
   ```
   NO_MATCH: path/to/file
   ```

3. **Missing Files**: 
   ```
   MISSING IN AWS: path/to/file
   MISSING IN CONTABO: path/to/file
   ```

## Typical Workflow

1. **Generate SHA manifests on both servers:**
   ```bash
   # On Server 1
   sudo bash gensha.sh /path/to/directory

   # On Server 2
   sudo bash gensha.sh /path/to/directory
   ```

2. **Copy manifest files to a common location**

3. **Compare the manifests:**
   ```bash
   # Simple comparison
   ./comparesha.sh -s manifest1.txt manifest2.txt

   # Detailed comparison showing only differences
   ./comparesha.sh -d manifest1.txt manifest2.txt

   # Full verbose comparison
   ./comparesha.sh -v manifest1.txt manifest2.txt
   ```

## Important Notes

- The scripts normalize paths by removing server-specific prefixes (AWS/ or Contabo/)
- The comparison script skips the first line of each manifest file
- Directory-level checksums (.shaignore) provide quick overall comparison
- Whitespace and indentation are ignored in checksum calculations
- Both scripts handle spaces in filenames correctly

## Error Handling

- Both scripts include basic error checking for required parameters
- The comparison script provides clear feedback about missing or mismatched files
- Color-coded output helps quickly identify issues

## Best Practices

1. Always run `gensha.sh` with sudo to ensure access to all files
2. Use the `-s` flag first for quick directory-level comparison
3. Use the `-d` flag to investigate specific differences
4. Use the `-v` flag when a complete audit trail is needed

## Limitations

- The scripts assume the manifest files follow the specified format
- Server names must be consistent across comparisons
- The scripts do not handle binary file comparisons specially
