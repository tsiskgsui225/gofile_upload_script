# Gofile Upload Script

## Installation

1.  **Download the script:**
    ```bash
    wget https://github.com/user-attachments/files/23481561/gofile.sh
    chmod +x gofile.sh
    ```

## Usage

The basic syntax for using the script is:

```bash
./gofile.sh [OPTIONS] <file_path>
```

### Options

-   `-f <folder_id>`: Upload to a specific folder ID.
-   `-r <region>`: Use a specific region for uploading. Available regions: `eu-par`, `na-phx`, `ap-sgp`, `ap-hkg`, `ap-tyo`, `sa-sao`.
-   `-l`: List files in the current directory.
-   `-d`: Enable debug mode to show the full API response.
-   `-h`: Show the help message.

### Examples

-   **Upload a file:**
    ```bash
    ./gofile.sh my_archive.zip
    ```

-   **Upload a file to a specific folder:**
    ```bash
    ./gofile.sh -f your_folder_id my_document.pdf
    ```

-   **Upload a file to a specific region:**
    ```bash
    ./gofile.sh -r eu-par my_video.mp4
    ```

-   **List files in the current directory:**
    ```bash
    ./gofile.sh -l
    ```
    
   Contributing

Contributions are welcome! If you have any improvements or bug fixes, feel free to open a pull request.
