#!/bin/bash

RED='\u001B[0;31m'
GREEN='\u001B[0;32m'
YELLOW='\u001B[1;33m'
BLUE='\u001B[0;34m'
NC='\u001B[0m'

# Your Gofile account tokens (add more tokens to the array)
TOKENS=(
    "l6AVXoGoaVpPtiAiOu2CKuzZutTpvQhu"
    # "put_your_second_token_here"
)

# Select a random token
TOKEN=${TOKENS[$RANDOM % ${#TOKENS[@]}]}

# Default upload endpoint (automatic region selection)
UPLOAD_ENDPOINT="https://upload.gofile.io/uploadfile"

# Function to display usage
usage() {
    echo -e "${BLUE}Usage:${NC} $0 [OPTIONS] <file_path>"
    echo ""
    echo "Options:"
    echo "  -f <folder_id>    Upload to specific folder ID"
    echo "  -r <region>       Use specific region (eu-par, na-phx, ap-sgp, ap-hkg, ap-tyo, sa-sao)"
    echo "  -l                List files in current directory"
    echo "  -d                Debug mode (show full response and file details)"
    echo "  -h                Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 file.zip"
    echo "  $0 -f abc123def file.zip"
    echo "  $0 -r eu-par file.zip"
    echo "  $0 -d file.zip"
    exit 1
}

# Function to check dependencies
check_dependencies() {
    local missing_deps=()
    
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo -e "${RED}Error: Missing required dependencies: ${missing_deps[*]}${NC}"
        echo "Please install them using your package manager."
        exit 1
    fi
}

# Function to format file size
format_size() {
    local size=$1
    if [ $size -lt 1024 ]; then
        echo "${size}B"
    elif [ $size -lt 1048576 ]; then
        printf "%.2fKB" $(awk "BEGIN {print $size/1024}")
    elif [ $size -lt 1073741824 ]; then
        printf "%.2fMB" $(awk "BEGIN {print $size/1048576}")
    else
        printf "%.2fGB" $(awk "BEGIN {print $size/1073741824}")
    fi
}

# Function to list files in current directory
list_files() {
    echo -e "${BLUE}Files in current directory:${NC}"
    echo ""
    local i=1
    for file in *; do
        if [ -f "$file" ]; then
            local size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null)
            local formatted_size=$(format_size $size)
            echo -e "${GREEN}[$i]${NC} $file ${YELLOW}($formatted_size)${NC}"
            ((i++))
        fi
    done
    echo ""
}

# Function to upload file
upload_file() {
    local file_path="$1"
    local folder_id="$2"
    local upload_url="$3"
    local debug_mode="$4"
    
    # Check if file exists
    if [ ! -f "$file_path" ]; then
        echo -e "${RED}Error: File '$file_path' not found${NC}"
        exit 1
    fi
    
    # Get file size
    local file_size=$(stat -c%s "$file_path" 2>/dev/null || stat -f%z "$file_path" 2>/dev/null)
    local formatted_size=$(format_size $file_size)
    
    echo -e "${BLUE}Uploading:${NC} $(basename "$file_path") ${YELLOW}($formatted_size)${NC}"
    echo ""
    
    # Create temporary file for response
    local temp_response=$(mktemp)
    
    # Prepare curl command
    if [ -n "$folder_id" ]; then
        echo -e "${BLUE}Uploading to folder:${NC} $folder_id"
        curl -X POST \
            -# \
            -H "Authorization: Bearer $TOKEN" \
            -F "file=@$file_path" \
            -F "folderId=$folder_id" \
            "$upload_url" > "$temp_response" 2>&1
    else
        curl -X POST \
            -# \
            -H "Authorization: Bearer $TOKEN" \
            -F "file=@$file_path" \
            "$upload_url" > "$temp_response" 2>&1
    fi
    
    echo ""
    
    # Read response
    local response=$(cat "$temp_response")
    
    # Debug mode - show full response
    if [ "$debug_mode" = true ]; then
        echo -e "${YELLOW}=== DEBUG: Full Response ===${NC}"
        echo "$response"
        echo -e "${YELLOW}=== END DEBUG ===${NC}"
        echo ""
    fi
    
    # Extract JSON from response (filter out progress bar)
    local json_response=$(echo "$response" | grep -o '{.*}' | tail -1)
    
    # Check if we got valid JSON
    if [ -z "$json_response" ]; then
        echo -e "${RED}Error: No JSON response received${NC}"
        echo -e "${YELLOW}Raw response:${NC}"
        echo "$response"
        rm -f "$temp_response"
        exit 1
    fi
    
    # Validate JSON
    if ! echo "$json_response" | jq . >/dev/null 2>&1; then
        echo -e "${RED}Error: Invalid JSON response${NC}"
        echo -e "${YELLOW}Response:${NC} $json_response"
        rm -f "$temp_response"
        exit 1
    fi
    
    # Parse status
    local status=$(echo "$json_response" | jq -r '.status // "unknown"')
    
    if [ "$status" == "ok" ]; then
        echo -e "${GREEN}✓ Upload successful!${NC}"
        echo ""
        
        # Extract data fields safely
        local download_page=$(echo "$json_response" | jq -r '.data.downloadPage // "N/A"')
        local file_id=$(echo "$json_response" | jq -r '.data.id // .data.fileId // "N/A"')
        local parent_folder=$(echo "$json_response" | jq -r '.data.parentFolder // "N/A"')
        local file_name=$(echo "$json_response" | jq -r '.data.name // .data.fileName // "N/A"')
        local md5=$(echo "$json_response" | jq -r '.data.md5 // "N/A"')
        
        # Only show details in debug mode
        if [ "$debug_mode" = true ]; then
            echo -e "${BLUE}File Details:${NC}"
            echo "  Name: $file_name"
            echo "  File ID: $file_id"
            echo "  Folder ID: $parent_folder"
            echo "  MD5: $md5"
            echo ""
        fi
        echo -e "${GREEN}Download Page:${NC} $download_page"
        echo ""
        
    else
        # Try to extract error message
        local error_msg=$(echo "$json_response" | jq -r '.error // .message // "Unknown error"')
        
        echo -e "${RED}✗ Upload failed!${NC}"
        echo -e "${RED}Status:${NC} $status"
        echo -e "${RED}Error:${NC} $error_msg"
        echo ""
        echo -e "${YELLOW}Full response:${NC}"
        echo "$json_response" | jq . 2>/dev/null || echo "$json_response"
        
        rm -f "$temp_response"
        exit 1
    fi
    
    # Clean up
    rm -f "$temp_response"
}

# Main script
main() {
    local file_path=""
    local folder_id=""
    local region=""
    local list_mode=false
    local debug_mode=false
    
    # Check dependencies
    check_dependencies
    
    # Parse command line arguments
    while getopts "f:r:ldh" opt; do
        case $opt in
            f)
                folder_id="$OPTARG"
                ;;
            r)
                region="$OPTARG"
                ;;
            l)
                list_mode=true
                ;;
            d)
                debug_mode=true
                ;;
            h)
                usage
                ;;
            *)
                usage
                ;;
        esac
    done
    
    shift $((OPTIND-1))
    
    # List mode
    if [ "$list_mode" = true ]; then
        list_files
        exit 0
    fi
    
    # Check if file path is provided
    if [ -z "$1" ]; then
        echo -e "${RED}Error: No file specified${NC}"
        echo ""
        usage
    fi
    
    file_path="$1"
    
    # Set upload endpoint based on region
    if [ -n "$region" ]; then
        case $region in
            eu-par)
                UPLOAD_ENDPOINT="https://upload-eu-par.gofile.io/uploadfile"
                echo -e "${BLUE}Using region:${NC} Europe (Paris)"
                ;;
            na-phx)
                UPLOAD_ENDPOINT="https://upload-na-phx.gofile.io/uploadfile"
                echo -e "${BLUE}Using region:${NC} North America (Phoenix)"
                ;;
            ap-sgp)
                UPLOAD_ENDPOINT="https://upload-ap-sgp.gofile.io/uploadfile"
                echo -e "${BLUE}Using region:${NC} Asia Pacific (Singapore)"
                ;;
            ap-hkg)
                UPLOAD_ENDPOINT="https://upload-ap-hkg.gofile.io/uploadfile"
                echo -e "${BLUE}Using region:${NC} Asia Pacific (Hong Kong)"
                ;;
            ap-tyo)
                UPLOAD_ENDPOINT="https://upload-ap-tyo.gofile.io/uploadfile"
                echo -e "${BLUE}Using region:${NC} Asia Pacific (Tokyo)"
                ;;
            sa-sao)
                UPLOAD_ENDPOINT="https://upload-sa-sao.gofile.io/uploadfile"
                echo -e "${BLUE}Using region:${NC} South America (São Paulo)"
                ;;
            *)
                echo -e "${YELLOW}Warning: Unknown region '$region', using automatic selection${NC}"
                ;;
        esac
    fi
    
    # Upload file
    upload_file "$file_path" "$folder_id" "$UPLOAD_ENDPOINT" "$debug_mode"
}

# Run main function
main "$@"