# Gofile Upload Script

This script allows you to upload files to [Gofile.io](https://gofile.io) from the command line.

## Features

-   Upload files to Gofile.io
-   Specify a folder to upload to
-   Select a specific server region for uploading
-   List files in the current directory
-   Debug mode for detailed output

## Prerequisites

Before using this script, you need to have the following installed:

-   `curl`: A command-line tool for transferring data with URL syntax.
-   `jq`: A lightweight and flexible command-line JSON processor.

## Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/tsiskgsui225/gofile_upload_script.git
    cd gofile_upload_script
    ```

2.  **Make the script executable:**
    ```bash
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

## Platform-Specific Instructions

### VPS (Linux)

Most Linux distributions come with `curl` pre-installed. You can install `jq` using your package manager.

-   **Debian/Ubuntu:**
    ```bash
    sudo apt-get update
    sudo apt-get install -y curl jq
    ```

-   **CentOS/RHEL:**
    ```bash
    sudo yum install -y curl jq
    ```

-   **Arch Linux:**
    ```bash
    sudo pacman -Syu curl jq
    ```

After installing the dependencies, you can follow the [Installation](#installation) and [Usage](#usage) sections above.

### Windows

You can use this script on Windows through one of the following methods:

#### 1. Windows Subsystem for Linux (WSL)

1.  [Install WSL](https://docs.microsoft.com/en-us/windows/wsl/install) on your Windows machine.
2.  Open a WSL terminal.
3.  Follow the instructions for [VPS (Linux)](#vps-linux) to install `curl` and `jq`.
4.  Follow the [Installation](#installation) and [Usage](#usage) instructions within your WSL environment.

#### 2. Git Bash

1.  [Install Git for Windows](https://git-scm.com/download/win), which includes Git Bash.
2.  Open Git Bash. `curl` is included with Git Bash.
3.  Install `jq` using a package manager like Chocolatey or Scoop, or by downloading the binary.
    -   **Using Chocolatey:**
        ```bash
        choco install jq
        ```
    -   **Using Scoop:**
        ```bash
        scoop install jq
        ```
4.  Follow the [Installation](#installation) and [Usage](#usage) instructions within Git Bash.

### Android (Termux)

You can run this script on Android using the [Termux](https://termux.com/) terminal emulator.

1.  Install Termux from the [F-Droid](https://f-droid.org/en/packages/com.termux/) store.
2.  Open Termux and install the necessary packages:
    ```bash
    pkg update && pkg upgrade
    pkg install -y curl jq git
    ```
3.  Follow the [Installation](#installation) and [Usage](#usage) instructions within Termux. To access your device's storage, you may need to run `termux-setup-storage`.

## Contributing

Contributions are welcome! If you have any improvements or bug fixes, feel free to open a pull request.
