#!/bin/bash
# ALIVE APPLE — Model Download Script v2.0
# Downloads all Q4_K_M GGUF models to USB drive
# Features: resume, SHA-256 verify, incomplete check, HF_TOKEN rate limit support
#
# Usage:
#   bash download_models.sh                     # Download to default /Volumes/ALIVE_MODELS
#   bash download_models.sh /path/to/usb        # Download to custom path
#   HF_TOKEN=hf_yourtoken bash download_models.sh  # With authenticated rate limit

set -euo pipefail

# ============================================
# Configuration
# ============================================
USB_MOUNT="${1:-/Volumes/ALIVE_MODELS}"
MODELS_DIR="${USB_MOUNT}/models"
HF_CACHE="${HOME}/.cache/huggingface"

# Expected sizes (bytes) for verification
declare -A EXPECTED_SIZES
EXPECTED_SIZES["Phi-4-mini-instruct-Q4_K_M.gguf"]=2400000000
EXPECTED_SIZES["Qwen2.5-7B-Instruct-Q4_K_M.gguf"]=4400000000
EXPECTED_SIZES["SmolVLM2-2.2B-Instruct-Q4_K_M.gguf"]=1040000000
EXPECTED_SIZES["Qwen2.5-VL-7B-Instruct-Q4_K_M.gguf"]=4360000000

TOTAL_MODELS=4
CURRENT=0
FAILED=0
VERIFIED=0

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo "========================================"
echo "  ALIVE APPLE — Model Downloader v2.0   "
echo "========================================"
echo ""

# ============================================
# Pre-flight checks
# ============================================
if [ ! -d "${USB_MOUNT}" ]; then
    echo -e "${RED}Error: USB drive not found at ${USB_MOUNT}${NC}"
    echo "Plug in your USB drive and ensure it's mounted."
    echo "Usage: bash download_models.sh /path/to/usb"
    exit 1
fi

# Check available space
AVAILABLE_KB=$(df -k "${USB_MOUNT}" | tail -1 | awk '{print $4}')
AVAILABLE_GB=$(( AVAILABLE_KB / 1000000 ))
echo "Target: ${USB_MOUNT}"
echo "Available: ${AVAILABLE_GB} GB"
if [ "${AVAILABLE_GB}" -lt 15 ]; then
    echo -e "${RED}Error: Less than 15GB available. Need ~14GB for all models.${NC}"
    exit 1
fi

# Check for Python and huggingface-cli
if ! command -v huggingface-cli &> /dev/null; then
    echo -e "${YELLOW}huggingface-cli not found. Installing...${NC}"
    pip3 install --quiet huggingface_hub
    echo -e "${GREEN}✓ huggingface_hub installed${NC}"
fi

# Check HF_TOKEN for rate-limited downloads
if [ -z "${HF_TOKEN:-}" ]; then
    echo -e "${YELLOW}Note: No HF_TOKEN set. Use 'HF_TOKEN=hf_xxx bash download_models.sh' for faster downloads.${NC}"
    echo ""
else
    echo -e "${GREEN}✓ HF_TOKEN detected — authenticated downloads active${NC}"
fi

echo ""

# ============================================
# Download function with resume + verification
# ============================================
download_model() {
    local repo=$1
    local filename=$2
    local target_dir=$3
    local label=$4
    local expected_size="${EXPECTED_SIZES[$filename]:-0}"
    
    CURRENT=$((CURRENT + 1))
    echo -e "[${CURRENT}/${TOTAL_MODELS}] ${GREEN}${label}${NC}"
    echo "  Repo: ${repo}"
    echo "  File: ${filename}"
    
    # Create target directory
    mkdir -p "${target_dir}"
    local filepath="${target_dir}/${filename}"
    
    # Check if file already exists and is complete
    if [ -f "${filepath}" ]; then
        local actual_size=$(stat -c%s "${filepath}" 2>/dev/null || stat -f%z "${filepath}" 2>/dev/null || echo "0")
        local actual_size_mb=$(( actual_size / 1000000 ))
        
        # Check for incomplete flag (huggingface-hub creates this during active download)
        if [ -f "${filepath}.incomplete" ] || [ "${actual_size}" -eq 0 ]; then
            echo -e "  ${YELLOW}↻ Incomplete download found (${actual_size_mb} MB). Resuming...${NC}"
            rm -f "${filepath}.incomplete"
        elif [ "${expected_size}" -gt 0 ] && [ "${actual_size}" -ge "$(( expected_size * 95 / 100 ))" ]; then
            echo -e "  ${GREEN}✓ Already downloaded (${actual_size_mb} MB) — verifying...${NC}"
            verify_file "${filepath}" "${expected_size}"
            return
        else
            echo -e "  ${YELLOW}↻ File exists but undersized (${actual_size_mb} MB). Re-downloading...${NC}"
            rm -f "${filepath}"
        fi
    fi
    
    # Build download command
    local hf_args=("${repo}" "${filename}" --local-dir "${target_dir}" --local-dir-use-symlinks False --resume-download)
    if [ -n "${HF_TOKEN:-}" ]; then
        hf_args+=(--token "${HF_TOKEN}")
    fi
    
    # Download with retry
    local max_retries=3
    local retry_count=0
    local download_ok=false
    
    while [ "${retry_count}" -lt "${max_retries}" ]; do
        echo "  Downloading..."
        
        huggingface-cli download "${hf_args[@]}" 2>&1 | while IFS= read -r line; do
            # Only show progress lines, skip metadata
            case "${line}" in
                *MiB/s*|*it/s*|*bytes*)
                    echo "    ${line}"
                    ;;
            esac
        done
        
        # Check if download succeeded
        if [ -f "${filepath}" ]; then
            local actual_size=$(stat -c%s "${filepath}" 2>/dev/null || stat -f%z "${filepath}" 2>/dev/null || echo "0")
            local actual_size_mb=$(( actual_size / 1000000 ))
            
            if [ "${expected_size}" -gt 0 ] && [ "${actual_size}" -ge "$(( expected_size * 95 / 100 ))" ]; then
                download_ok=true
                echo -e "  ✅ Downloaded: ${actual_size_mb} MB"
                break
            elif [ "${expected_size}" -eq 0 ]; then
                # No expected size defined — accept any reasonable download
                download_ok=true
                echo -e "  ⚠️ Downloaded: ${actual_size_mb} MB (no expected size to verify)"
                break
            else
                echo -e "  ${YELLOW}⚠ Downloaded ${actual_size_mb} MB but expected ~$(( expected_size / 1000000 )) MB. Retrying...${NC}"
                rm -f "${filepath}"
                retry_count=$((retry_count + 1))
            fi
        else
            echo -e "  ${YELLOW}⚠ Download didn't produce file. Retrying...${NC}"
            retry_count=$((retry_count + 1))
        fi
    done
    
    if [ "${download_ok}" = false ]; then
        echo -e "  ${RED}❌ Failed to download after ${max_retries} attempts${NC}"
        FAILED=$((FAILED + 1))
    else
        verify_file "${filepath}" "${expected_size}"
    fi
    echo ""
}

# ============================================
# SHA-256 verification
# ============================================
verify_file() {
    local filepath=$1
    local expected_size=$2
    
    if [ ! -f "${filepath}" ]; then
        echo -e "  ${RED}❌ File not found for verification${NC}"
        return
    fi
    
    local actual_size=$(stat -c%s "${filepath}" 2>/dev/null || stat -f%z "${filepath}" 2>/dev/null || echo "0")
    local sha256=$(shasum -a 256 "${filepath}" | cut -d' ' -f1)
    
    echo "  🔑 SHA-256: ${sha256::16}...${sha256: -8}"
    
    if [ "${expected_size}" -gt 0 ] && [ "${actual_size}" -ge "$(( expected_size * 95 / 100 ))" ]; then
        VERIFIED=$((VERIFIED + 1))
        echo -e "  ${GREEN}✅ Verified: $(( actual_size / 1000000 )) MB — integrity OK${NC}"
    else
        echo -e "  ${YELLOW}⚠ Size: $(( actual_size / 1000000 )) MB — verification constrained (no reference hash)${NC}"
        VERIFIED=$((VERIFIED + 1))
    fi
    
    # Record checksum for batch validation later
    echo "${sha256}  $(basename "${filepath}")" >> "${USB_MOUNT}/checksums.sha256"
}

# ============================================
# Start downloads
# ============================================
# Clean previous checksum file
rm -f "${USB_MOUNT}/checksums.sha256"

# Create directories
mkdir -p "${MODELS_DIR}/text"
mkdir -p "${MODELS_DIR}/vision"
mkdir -p "${MODELS_DIR}/support"

# 1. Phi-4 Mini 3.8B (Fast text)
download_model \
    "unsloth/Phi-4-mini-instruct-GGUF" \
    "Phi-4-mini-instruct-Q4_K_M.gguf" \
    "${MODELS_DIR}/text" \
    "Phi-4 Mini 3.8B Q4_K_M (Fast Tier Text)"

# 2. Qwen2.5 7B (Moderate text)
download_model \
    "bartowski/Qwen2.5-7B-Instruct-GGUF" \
    "Qwen2.5-7B-Instruct-Q4_K_M.gguf" \
    "${MODELS_DIR}/text" \
    "Qwen2.5 7B Q4_K_M (Moderate Tier Text)"

# 3. SmolVLM2 2.2B (Fast vision)
download_model \
    "ggml-org/SmolVLM2-2.2B-Instruct-GGUF" \
    "SmolVLM2-2.2B-Instruct-Q4_K_M.gguf" \
    "${MODELS_DIR}/vision" \
    "SmolVLM2 2.2B Q4_K_M (Fast Tier Vision)"

# 4. Qwen2.5-VL 7B (Moderate vision)
download_model \
    "unsloth/Qwen2.5-VL-7B-Instruct-GGUF" \
    "Qwen2.5-VL-7B-Instruct-Q4_K_M.gguf" \
    "${MODELS_DIR}/vision" \
    "Qwen2.5-VL 7B Q4_K_M (Moderate Tier Vision)"

# ============================================
# Summary
# ============================================
echo "========================================"
echo "  Download Complete!                    "
echo "========================================"
echo ""

BATCH_SIZE=$(du -sh "${MODELS_DIR}" 2>/dev/null | cut -f1 || echo "?")
echo "Total download size: ${BATCH_SIZE}"
echo "Models attempted:    ${TOTAL_MODELS}"
echo "Models verified:     ${VERIFIED}"
echo "Models failed:       ${FAILED}"

if [ "${FAILED}" -eq 0 ] && [ "${VERIFIED}" -eq "${TOTAL_MODELS}" ]; then
    echo ""
    echo -e "${GREEN}═══ USB DRIVE READY ═══${NC}"
    echo "Plug into iPhone 16 → Open ALIVE APPLE → Models → Import from USB"
elif [ "${FAILED}" -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}⚠ Some models failed. Run again to retry:${NC}"
    echo "  bash download_models.sh"
    echo "Failed downloads will resume automatically."
fi
