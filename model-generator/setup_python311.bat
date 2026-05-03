@echo off
echo ========================================
echo Python 3.11 Setup for Local GPU
echo ========================================
echo.

echo Step 1: Creating virtual environment with Python 3.11...
py -3.11 -m venv venv311

echo.
echo Step 2: Activating virtual environment...
call venv311\Scripts\activate.bat

echo.
echo Step 3: Upgrading pip...
python -m pip install --upgrade pip

echo.
echo Step 4: Installing basic dependencies...
pip install -r requirements.txt

echo.
echo Step 5: Installing PyTorch with CUDA support...
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

echo.
echo Step 6: Installing AI libraries...
pip install transformers diffusers accelerate scipy imageio

echo.
echo Step 7: Verifying GPU detection...
python -c "import torch; print(''); print('GPU Available:', torch.cuda.is_available()); print('GPU Name:', torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'None'); print('CUDA Version:', torch.version.cuda if torch.cuda.is_available() else 'None')"

echo.
echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo To use this environment in the future:
echo 1. Run: venv311\Scripts\activate.bat
echo 2. Run: python app.py
echo.
pause
