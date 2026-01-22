# Gofile Upload Script

A simple Bash script to upload files to Gofile.io with support for folder uploads and region selection.

## Quick Start

Run the following command to download and make the script executable:

```bash
wget https://raw.githubusercontent.com/tsiskgsui225/gofile_upload_script/main/gofile.sh && chmod +x gofile.sh
```

## Dependencies

- `curl`
- `jq`

## Usage

```bash
./gofile.sh [OPTIONS] <file_path>
```

### Options

| Flag | Description |
|------|-------------|
| `-f <folder_id>` | Upload to a specific Gofile folder ID. |
| `-r <region>` | Specify upload region (e.g., `eu-par`, `na-phx`, `ap-sgp`). |
| `-l` | List files in the current directory. |
| `-d` | Enable debug mode to see full API response. |
| `-h` | Show help message. |

### Examples

**Basic Upload:**
```bash
./gofile.sh archive.zip
```

**Upload to a specific folder:**
```bash
./gofile.sh -f "folder-id-here" image.png
```

**Upload using a specific region:**
```bash
./gofile.sh -r eu-par video.mp4
```
