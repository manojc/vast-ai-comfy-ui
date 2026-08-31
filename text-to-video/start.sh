#!/bin/bash

# Official Vast.ai template workspace path for ComfyUI models
COMFY_MODEL_BASE="/workspace/ComfyUI/models"

echo "Checking and provisioning model weights..."

# Ensure target subfolders exist
mkdir -p "$COMFY_MODEL_BASE/checkpoints"
mkdir -p "$COMFY_MODEL_BASE/animatediff_models"

# Define your models and their target subfolders
# Format: ["HuggingFace_Repo_ID:Filename"]="subfolder_inside_models"
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
    
    # Check if the specific model file already exists
    if [ -f "$target_file" ]; then
        echo "[SKIPPED] Model file already exists at $target_file. Skipping download."
    else
        echo "[DOWNLOADING] Pulling $filename from Hugging Face..."
        
        # Download using the hf CLI tool
        hf download "$repo" "$filename" --local-dir "$target_dir"
        
        if [ $? -eq 0 ]; then
            echo "Successfully downloaded: $filename"
        else
            echo "Error downloading: $filename from $repo" >&2
        fi
    fi
done

echo "Model provisioning complete!"