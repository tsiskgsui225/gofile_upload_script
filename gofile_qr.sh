#!/bin/bash

RED='\u001B[0;31m'
GREEN='\u001B[0;32m'
YELLOW='\u001B[1;33m'
BLUE='\u001B[0;34m'
NC='\u001B[0m'

# Telegram Config
TELEGRAM_BOT_TOKEN="YOUR_BOT_TOKEN"
TELEGRAM_CHAT_ID="YOUR_CHAT_ID"

TOKENS=(
    "l6AVXoGoaVpPtiAiOu2CKuzZutTpvQhu"
)
TOKEN=${TOKENS[$RANDOM % ${#TOKENS[@]}]}
UPLOAD_ENDPOINT="https://upload.gofile.io/uploadfile"

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

draw_bar() {
    local width=30
    local char_filled="█"
    local char_empty="░"
    
    while IFS= read -r -d $'\r' line; do
        read -r percent speed <<< $(echo "$line" | awk '{print $1, $12}')
        if [[ "$percent" =~ ^[0-9]+$ ]]; then
            local speed_display="$speed"
            if [[ "$speed" =~ ^[0-9]+$ ]]; then
                if [ "$speed" -ge 1048576 ]; then
                    speed_display=$(awk -v s="$speed" 'BEGIN {printf "%.1f MB/s", s/1048576}')
                elif [ "$speed" -ge 1024 ]; then
                    speed_display=$(awk -v s="$speed" 'BEGIN {printf "%.1f KB/s", s/1024}')
                else
                    speed_display="${speed} B/s"
                fi
            else
                 speed_display="${speed}/s"
            fi
            
            local num_filled=$(( (percent * width) / 100 ))
            local num_empty=$(( width - num_filled ))
            local bar=""
            for ((i=0; i<num_filled; i++)); do bar+="${char_filled}"; done
            for ((i=0; i<num_empty; i++)); do bar+="${char_empty}"; done
            printf "\033[1G\033[K${BLUE}Uploading: [${bar}] ${percent}%%   ${speed_display}${NC}"
        fi
    done
    echo ""
}

upload_file() {
    local file_path="$1"
    local folder_id="$2"
    local upload_url="$3"
    local debug_mode="$4"
    
    if [ ! -f "$file_path" ]; then
        echo -e "${RED}Error: File '$file_path' not found${NC}"
        exit 1
    fi
    
    local file_size=$(stat -c%s "$file_path" 2>/dev/null || stat -f%z "$file_path" 2>/dev/null)
    local formatted_size=$(format_size $file_size)
    
    echo -e "${BLUE}Uploading:${NC} $(basename "$file_path") ${YELLOW}($formatted_size)${NC}"
    echo ""
    
    local temp_response=$(mktemp)
    
    local start_time=$(date +%s.%N)
    
    if [ -n "$folder_id" ]; then
        echo -e "${BLUE}Uploading to folder:${NC} $folder_id"
        { curl -X POST \
            -H "Authorization: Bearer $TOKEN" \
            -F "file=@$file_path" \
            -F "folderId=$folder_id" \
            "$upload_url" 2>&1 1>&3 | draw_bar; } 3> "$temp_response"
    else
        { curl -X POST \
            -H "Authorization: Bearer $TOKEN" \
            -F "file=@$file_path" \
            "$upload_url" 2>&1 1>&3 | draw_bar; } 3> "$temp_response"
    fi
    
    local end_time=$(date +%s.%N)
    
    echo ""
    local response=$(cat "$temp_response")
    
    if [ "$debug_mode" = true ]; then
        echo -e "${YELLOW}=== DEBUG: Full Response ===${NC}"
        echo "$response"
        echo -e "${YELLOW}=== END DEBUG ===${NC}"
        echo ""
    fi
    
    local json_response=$(echo "$response" | grep -o '{.*}' | tail -1)
    if [ -z "$json_response" ]; then
        echo -e "${RED}Error: No JSON response received${NC}"
        echo -e "${YELLOW}Raw response:${NC}"
        echo "$response"
        rm -f "$temp_response"
        exit 1
    fi
    
    if ! echo "$json_response" | jq . >/dev/null 2>&1; then
        echo -e "${RED}Error: Invalid JSON response${NC}"
        echo -e "${YELLOW}Response:${NC} $json_response"
        rm -f "$temp_response"
        exit 1
    fi
    
    local status=$(echo "$json_response" | jq -r '.status // "unknown"')
    if [ "$status" == "ok" ]; then
        local time_msg=$(awk -v start="$start_time" -v end="$end_time" 'BEGIN {
            duration = end - start;
            if (duration < 60) {
                printf "%.2f sec", duration
            } else {
                mins = int(duration/60);
                secs = duration % 60;
                printf "%d min %.2f sec", mins, secs
            }
        }')
        echo -e "${GREEN}✓ Upload successful!${NC} ${YELLOW}(Done in $time_msg)${NC}"
        echo ""
        local download_page=$(echo "$json_response" | jq -r '.data.downloadPage // "N/A"')
        local file_id=$(echo "$json_response" | jq -r '.data.id // .data.fileId // "N/A"')
        local parent_folder=$(echo "$json_response" | jq -r '.data.parentFolder // "N/A"')
        local file_name=$(echo "$json_response" | jq -r '.data.name // .data.fileName // "N/A"')
        local md5=$(echo "$json_response" | jq -r '.data.md5 // "N/A"')
        
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
        
        # Generate and display QR code
        echo -e "${BLUE}QR Code:${NC}"
        curl -s "https://qrenco.de/$download_page"
        echo ""
        
        # Send Telegram Notification
        if [ "$TELEGRAM_BOT_TOKEN" != "YOUR_BOT_TOKEN" ] && [ "$TELEGRAM_CHAT_ID" != "YOUR_CHAT_ID" ]; then
            echo -e "${BLUE}Sending Telegram Notification...${NC}"
            curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
                -d chat_id="$TELEGRAM_CHAT_ID" \
                -d text="✅ *Upload Complete!*
                
📂 *File:* $file_name
📦 *Size:* $formatted_size
🔗 *Link:* $download_page
⏱ *Time:* $time_msg
" \
                -d parse_mode="Markdown" > /dev/null
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✓ Notification sent!${NC}"
            else
                echo -e "${RED}✗ Notification failed!${NC}"
            fi
            echo ""
        else
            echo -e "${YELLOW}Tip: Configure TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID in the script to enable notifications.${NC}"
            echo ""
        fi
    else
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
    rm -f "$temp_response"
}

main() {
    local file_path=""
    local folder_id=""
    local region=""
    local list_mode=false
    local debug_mode=false
    
    check_dependencies
    
    while getopts "f:r:ldh" opt; do
        case $opt in
            f) folder_id="$OPTARG" ;;
            r) region="$OPTARG" ;;
            l) list_mode=true ;;
            d) debug_mode=true ;;
            h) usage ;;
            *) usage ;;
        esac
    done
    shift $((OPTIND-1))
    
    if [ "$list_mode" = true ]; then
        list_files
        exit 0
    fi
    
    if [ -z "$1" ]; then
        echo -e "${RED}Error: No file specified${NC}"
        echo ""
        usage
    fi
    file_path="$1"
    
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
    upload_file "$file_path" "$folder_id" "$UPLOAD_ENDPOINT" "$debug_mode"
}

main "$@"  