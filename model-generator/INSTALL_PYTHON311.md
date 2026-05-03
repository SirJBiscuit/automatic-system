# Install Python 3.11 (Keep Python 3.13)

You don't need to uninstall Python 3.13! You can have both versions installed.

## Automatic Installation

### Step 1: Download Python 3.11
Click this link and download the installer:
https://www.python.org/ftp/python/3.11.8/python-3.11.8-amd64.exe

Or go to the official page and click "Windows installer (64-bit)":
https://www.python.org/downloads/release/python-3118/

### Step 2: Install Python 3.11
1. Run the downloaded `python-3.11.8-amd64.exe`
2. ✅ **CHECK**: "Add Python 3.11 to PATH"
3. ✅ **CHECK**: "Install for all users" (optional)
4. Click "Install Now"
5. Wait for installation
6. Click "Close"

### Step 3: Run Automated Setup
After Python 3.11 is installed, double-click this file:
```
setup_python311.bat
```

This will automatically:
- Create a Python 3.11 virtual environment
- Install all dependencies
- Install PyTorch with CUDA
- Install AI libraries
- Test your GPU

**Time required**: 10-15 minutes (mostly downloading)

### Step 4: Run the App
From now on, use this to start the server:
```
run_with_python311.bat
```

## Manual Commands (if batch files don't work)

```bash
# Create virtual environment with Python 3.11
py -3.11 -m venv venv311

# Activate it
venv311\Scripts\activate

# Install everything
pip install -r requirements.txt
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
pip install transformers diffusers accelerate scipy imageio

# Run the app
python app.py
```

## Verify It's Working

After running `setup_python311.bat`, you should see:
```
GPU Available: True
GPU Name: NVIDIA GeForce RTX 4060 Ti
CUDA Version: 11.8
```

## Both Python Versions Will Coexist

- Python 3.13: Your system default
- Python 3.11: For this project only (in `venv311` folder)
- No conflicts!

## Quick Start Summary

1. Download: https://www.python.org/ftp/python/3.11.8/python-3.11.8-amd64.exe
2. Install (check "Add to PATH")
3. Double-click: `setup_python311.bat`
4. Wait 10-15 minutes
5. Double-click: `run_with_python311.bat`
6. Generate 3D models with your GPU! 🚀
