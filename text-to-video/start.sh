#!/bin/bash

# Vast.ai ComfyUI template persistent workspace paths
COMFY_BASE="/workspace/ComfyUI"
COMFY_MODEL_BASE="$COMFY_BASE/models"
CUSTOM_NODES_DIR="$COMFY_BASE/custom_nodes"

echo "Starting automated provisioning for models and custom nodes..."

# 1. Ensure model subfolders exist
mkdir -p "$COMFY_MODEL_BASE/checkpoints"
mkdir -p "$COMFY_MODEL_BASE/animatediff_models"

# 2. Ensure custom nodes directory exists
mkdir -p "$CUSTOM_NODES_DIR"

# -------------------------------------------------------------
# PART A: Clone Required Custom Nodes
# -------------------------------------------------------------
# Declare custom nodes to install: ["GitHub_Repo_URL"]="folder_name"
declare -A NODES=(
    ["https://github.com/Kosinkadink/ComfyUI-AnimateDiff-Evolved"]="ComfyUI-AnimateDiff-Evolved"
)

for repo_url in "${!NODES[@]}"; do
    folder_name="${NODES[$repo_url]}"
    target_node_dir="$CUSTOM_NODES_DIR/$folder_name"
    
    echo "--------------------------------------------------"
    echo "Checking custom node: $folder_name"
    
    if [ -d "$target_node_dir" ]; then
        echo "[SKIPPED] Custom node already exists at $target_node_dir."
    else
        echo "[CLONING] Downloading custom node from $repo_url..."
        git clone "$repo_url" "$target_node_dir"
        
        # Optional: If the custom node has a requirements.txt, auto-install Python dependencies
        if [ -f "$target_node_dir/requirements.txt" ]; then
            echo "[INSTALLING DEPENDencies] Found requirements.txt for $folder_name..."
            pip install --no-cache-dir -r "$target_node_dir/requirements.txt"
        fi
    fi
done

# -------------------------------------------------------------
# PART B: Download Model Weights
# -------------------------------------------------------------
declare -A MODELS=(
    ["stabilityai/stable-diffusion-xl-base-1.0:sd_xl_base_1.0.safetensors"]="checkpoints"
    ["guoyww/animatediff:mm_sdxl_v10_beta.ckpt"]="animatediff_models"
)

for entry in "${!MODELS[@]}"; do
    repo="${entry%%:*}"
    filename="${entry##*:}"
    subfolder="${MODELS[$entry]}"
    
    target_dir="$COMFY_MODEL_BASE/$subfolder"
    target_file="$target_dir/$filename"
    
    echo "--------------------------------------------------"
    echo "Checking model: $filename in $target_dir"
    
    if [ -f "$target_file" ]; then
        echo "[SKIPPED] Model file already exists at $target_file."
    else
        echo "[DOWNLOADING] Pulling $filename from Hugging Face..."
        hf download "$repo" "$filename" --local-dir "$target_dir"
        
        if [ $? -eq 0 ]; then
            echo "Successfully downloaded: $filename"
        else
            echo "Error downloading: $filename from $repo" >&2
        fi
    fi
done

echo "Provisioning complete! Starting ComfyUI..."