# 1. Start from an official NVIDIA CUDA 13.2 base image
FROM nvidia/cuda:13.2.0-runtime-ubuntu22.04

# Prevent interactive prompts during apt install
ENV DEBIAN_FRONTEND=noninteractive

# 2. Setup system dependencies and install Python 3.12 via deadsnakes PPA
RUN apt-get update && apt-get install -y \
    software-properties-common \
    git \
    curl \
    && add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update && apt-get install -y \
    python3.12 \
    python3.12-dev \
    python3.12-venv \
    && rm -rf /var/lib/apt/lists/*

# Make python3.12 the default python3 and install pip
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1 \
    && curl -sS https://bootstrap.pypa.io/get-pip.py | python3

WORKDIR /opt

# 3. Setup ComfyUI (clone repo & install core requirements + PyTorch)
RUN git clone --branch v0.33.1 --depth 1 https://github.com/comfyanonymous/ComfyUI.git

WORKDIR /opt/ComfyUI

# Install PyTorch (matching your CUDA stack) and core ComfyUI dependencies
RUN pip install --no-cache-dir torch torchvision torchaudio
RUN pip install --no-cache-dir -r requirements.txt

# 4 & 5. Add ComfyUI-Manager and required custom nodes
WORKDIR /opt/ComfyUI/custom_nodes

# Install ComfyUI-Manager
RUN git clone https://github.com/comfy-org/ComfyUI-Manager.git

# Add your specific custom nodes here (add as many as you need)
RUN git clone https://github.com/cubiq/ComfyUI_IPAdapter_plus

# ==============================================================================
# AUTOMATIC DEPENDENCY INSTALLER FOR ALL CUSTOM NODES
# ==============================================================================
# This scans every subfolder inside custom_nodes for a requirements.txt file 
# and automatically installs them via pip.
# ==============================================================================
RUN cd /opt/ComfyUI && \
    find /opt/ComfyUI/custom_nodes -maxdepth 2 -name "requirements.txt" | while read req; do \
        echo "Installing dependencies from: $req"; \
        pip install --no-cache-dir -r "$req"; \
    done

# Install huggingface_hub for model downloading
RUN pip install --no-cache-dir -U huggingface_hub

# 6. Expose port and start ComfyUI
WORKDIR /opt/ComfyUI
EXPOSE 8180

CMD ["python3", "main.py", "--listen", "0.0.0.0", "--port", "8180"]

# docker build -t manojchalode/comfyui-vast-ai:latest .
# docker tag manojchalode/comfyui-vast-ai:latest manojchalode/comfyui:0.0.1
# docker run -e HF_TOKEN="$HF_TOKEN" -it --rm -p 8180:8180 manojchalode/comfyui-vast-ai:latest
# docker push manojchalode/comfyui-vast-ai:latest