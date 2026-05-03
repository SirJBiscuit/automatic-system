# Installation Guide

## Quick Start (No GPU Required)

For **immediate use** without GPU setup:

1. **Install basic dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Start the server:**
   ```bash
   python app.py
   ```

3. **Use cloud providers:**
   - Select "Meshy AI" or "Tripo AI" in the web interface
   - Sign up for free trial at:
     - Meshy AI: https://meshy.ai (200 free credits)
     - Tripo AI: https://tripo3d.ai

## GPU Setup (For Local Free Generation)

### Prerequisites

1. **NVIDIA GPU** with 6GB+ VRAM
2. **NVIDIA Drivers** - Download from: https://www.nvidia.com/drivers
3. **CUDA Toolkit 11.8** - Download from: https://developer.nvidia.com/cuda-11-8-0-download-archive

### Installation Steps

#### Step 1: Install CUDA Toolkit

1. Download CUDA 11.8 from NVIDIA
2. Run the installer
3. Restart your computer

#### Step 2: Verify CUDA Installation

```bash
nvcc --version
```

Should show CUDA version 11.8.x

#### Step 3: Install Python Dependencies

```bash
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
pip install transformers diffusers accelerate scipy imageio
```

#### Step 4: Verify GPU Detection

```bash
python -c "import torch; print(f'GPU: {torch.cuda.is_available()}'); print(f'Name: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"None\"}')"
```

Should output:
```
GPU: True
Name: NVIDIA GeForce RTX 3080 (or your GPU model)
```

#### Step 5: Start Server

```bash
python app.py
```

You should see:
```
✅ GPU Detected: NVIDIA GeForce RTX 3080
   CUDA Version: 11.8
   GPU Memory: 10.0 GB
```

## Troubleshooting

### "OSError: DLL load failed"

**Cause:** CUDA Toolkit not installed or wrong version

**Solution:**
1. Install CUDA Toolkit 11.8 from NVIDIA
2. Restart computer
3. Reinstall PyTorch:
   ```bash
   pip uninstall torch torchvision torchaudio
   pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
   ```

### "No GPU detected"

**Cause:** NVIDIA drivers not installed

**Solution:**
1. Download latest drivers from: https://www.nvidia.com/drivers
2. Install and restart
3. Verify with: `nvidia-smi`

### "Out of memory" during generation

**Cause:** Insufficient GPU VRAM

**Solution:**
- Close other GPU applications
- Use cloud providers instead (Meshy AI, Tripo AI)
- Upgrade to GPU with more VRAM

## Recommended Setup

### For Best Experience:

**Option 1: Cloud (Easiest)**
- No GPU setup needed
- Sign up for Meshy AI free trial
- Get 200 free credits (~20 models)
- High quality results

**Option 2: Local GPU (Free Forever)**
- Requires NVIDIA GPU setup
- Unlimited free generations
- Completely private
- One-time setup effort

**Option 3: Hybrid**
- Use cloud for high-quality models
- Use local GPU for testing/iterations
- Best of both worlds

## System Requirements

### Minimum (Cloud Only)
- Windows 10/11
- 4GB RAM
- Internet connection

### Recommended (Local GPU)
- Windows 10/11
- NVIDIA GPU with 8GB+ VRAM
- 16GB System RAM
- CUDA 11.8 installed

### Optimal (Local GPU)
- Windows 11
- NVIDIA RTX 3060 or better
- 32GB System RAM
- CUDA 11.8 or 12.x
- SSD storage

## Next Steps

1. **Test the system:**
   - Open http://localhost:5000
   - Try generating a simple model
   - Download and view in Blender

2. **Choose your provider:**
   - Local GPU (free, unlimited)
   - Meshy AI (high quality, free trial)
   - Tripo AI (fast, free trial)

3. **Start creating!**
   - Experiment with prompts
   - Try different clothing options
   - Generate character variations

Need help? Check `SETUP_GPU.md` for detailed GPU configuration!
