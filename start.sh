#!/bin/bash

# Keep model downloads on Vast's persistent /workspace volume.
COMFYUI_DIR="/opt/ComfyUI"
COMFY_MODEL_BASE="/workspace/models"

# Create the base directory for models if it doesn't exist
mkdir -p "$COMFY_MODEL_BASE"

# Ensure subfolders expected by ComfyUI exist persistently
mkdir -p "$COMFY_MODEL_BASE/checkpoints"
mkdir -p "$COMFY_MODEL_BASE/animatediff_models"

# Create a symlink from ComfyUI's models directory to the persistent volume, if it doesn't already exist
if [ ! -L "$COMFYUI_DIR/models" ]; then
    echo "Linking ComfyUI models folder to persistent /workspace storage..."
    rm -rf "$COMFYUI_DIR/models"
    ln -s "$COMFY_MODEL_BASE" "$COMFYUI_DIR/models"
fi

# Define your models and their target subfolders relative to /workspace/models
# Format: ["HuggingFace_Repo_ID:Filename"]="subfolder_inside_models"
declare -A MODELS=(
    ["stabilityai/stable-diffusion-xl-base-1.0:sd_xl_base_1.0.safetensors"]="checkpoints"
    ["guoyww/animatediff:mm_sdxl_v10_beta.ckpt"]="animatediff_models"
)

echo "Checking model weights..."

for entry in "${!MODELS[@]}"; do
    # Split repo and filename using bash parameter expansion
    repo="${entry%%:*}"
    filename="${entry##*:}"
    subfolder="${MODELS[$entry]}"
    
    target_dir="$COMFY_MODEL_BASE/$subfolder"
    target_file="$target_dir/$filename"
    
    echo "--------------------------------------------------"
    echo "Checking model: $filename in $target_dir"
    
    # Ensure target subfolder exists
    mkdir -p "$target_dir"
    
    # Check if the specific model file already exists
    if [ -f "$target_file" ]; then
        echo "[SKIPPED] Model file already exists at $target_file. Skipping download."
    else
        echo "[DOWNLOADING] Model not found locally. Pulling $filename from Hugging Face..."
        
        # Download using the hf CLI tool
        hf download "$repo" "$filename" --local-dir "$target_dir"
        
        if [ $? -eq 0 ]; then
            echo "Successfully downloaded: $filename"
        else
            echo "Error downloading: $filename from $repo" >&2
        fi
    fi
done

echo "Model initialization complete!"

# Start ComfyUI
echo "Starting ComfyUI..."
cd "$COMFYUI_DIR"
exec python3 main.py --listen 0.0.0.0 --port 8180