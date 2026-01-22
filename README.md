# Gofile Upload Script (QR + Telegram Edition)

A powerful Bash script to upload files to Gofile.io with a stylish UI, real-time speed, QR code generation, and Telegram notifications.

## ✨ Features

- **Stylish Progress Bar**: Unicode block design `[████░░░░]`.
- **Real-Time Speed**: Displays current upload speed in MB/s or KB/s.
- **Upload Timer**: Shows exact duration (`Done in 1 min 23.45 sec`).
- **QR Code Generation**: Instantly generates a QR code in the terminal for the download link.
- **Telegram Notifications**: Sends a message to your Telegram bot with file details and link.
- **Region Support**: Choose specific upload regions (EU, NA, Asia, etc.).

## 🚀 Quick Start

Run the following command to download and make the script executable:

```bash
wget https://raw.githubusercontent.com/tsiskgsui225/gofile_upload_script/feat/qr-code/gofile_qr.sh && chmod +x gofile_qr.sh
```

## ⚙️ Configuration

### Telegram Notifications (Optional)
To enable Telegram notifications, open the script(`gofile_qr.sh`) and edit the top section:

```bash
# Telegram Config
TELEGRAM_BOT_TOKEN="YOUR_BOT_TOKEN_HERE"
TELEGRAM_CHAT_ID="YOUR_CHAT_ID_HERE"
```

1. Get a **Bot Token** from [@BotFather](https://t.me/BotFather).
2. Get your **Chat ID** from [@userinfobot](https://t.me/userinfobot).

## 📦 Dependencies

- `curl` (Network requests)
- `jq` (JSON parsing)
- `awk` (Math/Text processing)

## 🛠 Usage

```bash
./gofile_qr.sh [OPTIONS] <file_path>
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
./gofile_qr.sh archive.zip
```

**Upload to a specific folder:**
```bash
./gofile_qr.sh -f "folder-id-here" image.png
```

**Upload using a specific region:**
```bash
./gofile_qr.sh -r eu-par video.mp4
```
