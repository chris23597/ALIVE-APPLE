# ALIVE APPLE — USB Key Setup Guide

**Version:** 1.0.0  
**Drive Type:** USB-C Flash Drive, 256GB  
**File System:** exFAT  

---

## 1. Why exFAT?

- **Native iOS support:** iPhone 16 with USB-C reads exFAT natively via Files app
- **Cross-platform:** Works on macOS, Windows, Linux — download models anywhere
- **Large file support:** Handles 4GB+ model files (FAT32 limit is 4GB)
- **No journaling overhead:** Simpler than NTFS/APFS for read-heavy model storage

---

## 2. Formatting the USB Drive

### 2.1 On macOS

```bash
# List drives to identify USB
diskutil list

# Format as exFAT (replace disk4 with your USB identifier)
sudo diskutil eraseDisk exFAT "ALIVE_MODELS" GPT /dev/disk4

# Verify
diskutil info /Volumes/ALIVE_MODELS | grep "File System"
# File System: exFAT
```

### 2.2 On Windows

```powershell
# In PowerShell (Admin)
# List drives
Get-Disk | Where-Object BusType -eq "USB"

# Format (replace 4 with correct disk number)
Format-Volume -DriveLetter D -FileSystem exFAT -NewFileSystemLabel "ALIVE_MODELS" -Confirm:$false

# Or via GUI:
# Right-click USB drive → Format → exFAT → Allocation unit: 128KB → Quick Format
```

### 2.3 On Linux

```bash
# List drives
lsblk

# Format (replace /dev/sdb1 with your USB partition)
sudo mkfs.exfat -n ALIVE_MODELS /dev/sdb1
```

---

## 3. Directory Structure on USB

```
/Volumes/ALIVE_MODELS/
├── models/
│   ├── text/
│   │   ├── Phi-4-mini-instruct-Q4_K_M.gguf        (~2.4 GB)
│   │   └── qwen2.5-7b-instruct-Q4_K_M.gguf        (~4.4 GB)
│   ├── vision/
│   │   ├── SmolVLM2-2.2B-Instruct-Q4_K_M.gguf     (~1.4 GB)
│   │   └── qwen2.5-vl-7b-instruct-Q4_K_M.gguf     (~4.7 GB)
│   └── support/
│       ├── all-MiniLM-L6-v2.mlmodelc               (~90 MB)
│       └── whisper-small.mlmodelc                   (~180 MB)
├── checksums.sha256
├── MODEL_INVENTORY.md                               (copy for reference)
└── README.txt                                       (quick start)
```

### README.txt content

```
ALIVE APPLE — Model Pack v1.0
==============================

These models power ALIVE APPLE, an on-device AI agent for iPhone 16.

To import:
1. Plug this USB drive into your iPhone 16
2. Open ALIVE APPLE
3. Go to Models → Import from USB
4. Select the models you want

Models included:
- Phi-4 Mini 3.8B (Fast text) — 2.4 GB
- Qwen2.5 7B (Moderate text) — 4.4 GB
- SmolVLM2 2.2B (Fast vision) — 1.4 GB
- Qwen2.5-VL 7B (Moderate vision) — 4.7 GB

Total: ~12.9 GB

All models are Q4_K_M quantized GGUF format.
Compatible with llama.cpp, MLX, and ALIVE APPLE.

Questions? See: docs.aliveapple.com
```

---

## 4. Downloading Models to USB

### Option A: Use download script (recommended)

```bash
cd ~/Projects/ALIVE_APPLE/Scripts

# Set USB path
export USB_MOUNT="/Volumes/ALIVE_MODELS"

# Run download
bash download_models.sh
```

### Option B: Manual download

```bash
# Install huggingface-cli
pip install huggingface_hub

# Set USB path
USB="/Volumes/ALIVE_MODELS/models"

# Download Fast text model
huggingface-cli download microsoft/Phi-4-mini-instruct-gguf \
    Phi-4-mini-instruct-Q4_K_M.gguf \
    --local-dir "$USB/text/"

# Download Moderate text model
huggingface-cli download Qwen/Qwen2.5-7B-Instruct-GGUF \
    qwen2.5-7b-instruct-Q4_K_M.gguf \
    --local-dir "$USB/text/"

# Download Fast vision model
huggingface-cli download HuggingFaceM4/SmolVLM2-2.2B-Instruct \
    --include="*Q4_K_M*" \
    --local-dir "$USB/vision/"

# Download Moderate vision model
huggingface-cli download Qwen/Qwen2.5-VL-7B-Instruct-GGUF \
    --include="*Q4_K_M*" \
    --local-dir "$USB/vision/"
```

---

## 5. Importing to iPhone 16

### 5.1 Via Files App

1. Plug USB-C drive into iPhone 16
2. Open **Files** app
3. Tap **Browse** → locate USB drive under "Locations"
4. Navigate to `/models/text/`
5. Long-press on a `.gguf` file → **Share**
6. Scroll to **ALIVE APPLE** in the share sheet
7. App opens → confirms import → copies to local storage

### 5.2 Via ALIVE APPLE (Built-in Importer)

1. Plug USB-C drive into iPhone 16
2. Open **ALIVE APPLE**
3. Tap **Models** tab → **Import from USB**
4. App auto-detects available GGUF/MLX/CoreML files
5. Select models to import (checkboxes)
6. Tap **Import Selected**
7. Progress bar shows copy progress
8. Models appear as "Ready" when import completes

### 5.3 Space Requirements

- iPhone needs **free space = total selected model sizes × 1.1** (10% buffer)
- Importing all 4 models needs ~14.2 GB free on iPhone
- Fast tier only needs ~3.8 GB free

---

## 6. Troubleshooting

| Issue | Solution |
|-------|----------|
| **USB not detected on iPhone** | Ensure USB-C connection is secure. Try different cable. Check USB has power LED. |
| **"Format not supported"** | Reformat as exFAT. NTFS and APFS are not supported by iOS Files app. |
| **Model import fails at 99%** | Check iPhone storage space. Delete unused apps. |
| **"File too large"** | Must be exFAT — FAT32 has 4GB file size limit. Some models exceed this. |
| **Import speed is slow** | USB 2.0 drives: ~30 MB/s (4.7GB ≈ 3 min). USB 3.2 drives: ~300 MB/s (4.7GB ≈ 15s). |
| **SHA-256 mismatch** | Re-download the model. File may be corrupted. |
| **iPhone doesn't provide enough power** | Some drives need powered USB-C hub. Use a low-power SSD or flash drive. |

---

## 7. Maintaining the USB Drive

### Periodic Checks

```bash
# Verify file integrity
cd /Volumes/ALIVE_MODELS
shasum -a 256 -c checksums.sha256

# Check for file system errors
# macOS:
diskutil verifyVolume /Volumes/ALIVE_MODELS

# Windows:
chkdsk D: /f

# Linux:
sudo fsck.exfat /dev/sdb1
```

### Safely Eject

Always eject before unplugging:
- **macOS:** Right-click drive → Eject, or `diskutil eject /Volumes/ALIVE_MODELS`
- **Windows:** Taskbar → Safely Remove Hardware
- **iPhone:** Files app → ⏏ button next to drive name

---

## 8. ALIVE vs ALIVE APPLE Model Separation

| | ALIVE (Windows) | ALIVE APPLE (iOS) |
|---|---|---|
| **Drive** | D: (Windows USB) | USB-C (exFAT) |
| **Models** | Ollama format (blobs) | GGUF Q4_K_M raw files |
| **Location** | `D:\ALIVE_models\` | `/Volumes/ALIVE_MODELS/models/` |
| **Managed by** | Ollama server | ALIVE APPLE app |
| **Formats** | .gguf (Ollama-cached) | .gguf, .mlx, .mlmodelc |

**Rule:** Keep models on separate USB drives. ALIVE-APPLE models live on a dedicated USB-C drive formatted exFAT.  
Do NOT mix ALIVE (Windows) models on the same physical drive — different formats, different management.

---

*Your 256GB USB drive can hold all four ALIVE APPLE models (~13 GB) plus room for future models and document RAG storage.*
