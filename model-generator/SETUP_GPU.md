# 🚀 GPU Setup Guide - Local 3D Model Generation

## Quick Setup (5 minutes)

### 1. Install GPU Dependencies

```bash
pip install -r requirements-full.txt
```

**Note:** This will download ~4GB of packages including PyTorch with CUDA support.

### 2. Verify GPU Detection

```bash
python -c "import torch; print(f'GPU Available: {torch.cuda.is_available()}'); print(f'GPU Name: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"None\"}')"
```

You should see:
```
GPU Available: True
GPU Name: NVIDIA GeForce RTX 3080 (or your GPU model)
```

### 3. Start the Server

```bash
python app.py
```

### 4. Generate Your First Model

1. Open http://localhost:5000
2. Select "Local GPU (Your Server - FREE 3D!)"
3. Enter a prompt like "muscular warrior with armor"
4. Click "Generate 3D Model"
5. Wait 2-3 minutes for first generation (model loading)
6. Download your .ply or .obj file!

## Performance

### First Generation
- **Time:** 2-3 minutes (model downloads and loads into GPU memory)
- **VRAM Usage:** ~4-6GB

### Subsequent Generations
- **Time:** 30-60 seconds per model
- **VRAM Usage:** ~4-6GB (model stays loaded)

## GPU Requirements

### Minimum
- **GPU:** NVIDIA GPU with 6GB+ VRAM
- **CUDA:** Version 11.8 or higher
- **RAM:** 8GB system RAM

### Recommended
- **GPU:** NVIDIA RTX 3060 or better (8GB+ VRAM)
- **CUDA:** Version 12.0+
- **RAM:** 16GB system RAM

### Supported GPUs
- ✅ RTX 4090, 4080, 4070
- ✅ RTX 3090, 3080, 3070, 3060
- ✅ RTX 2080 Ti, 2080, 2070
- ✅ Tesla T4, V100, A100
- ⚠️ GTX 1080 Ti (marginal, 11GB VRAM)
- ❌ GTX 1060, 1070 (insufficient VRAM)

## Output Formats

The local generator creates:
- **`.ply` files** - Point cloud format (always generated)
- **`.obj` files** - Mesh format (when possible)

Both are compatible with:
- Blender
- MeshLab
- CloudCompare
- Unity
- Unreal Engine

## Advantages of Local Generation

✅ **100% Free** - No API costs, unlimited generations
✅ **Private** - Your data never leaves your server
✅ **Fast** - After first load, 30-60 seconds per model
✅ **Unlimited** - No rate limits or quotas
✅ **Offline** - Works without internet (after initial model download)

## Troubleshooting

### "CUDA out of memory"
- Close other GPU applications
- Reduce `frame_size` in code (default: 256)
- Restart the server to clear GPU memory

### "No GPU detected"
- Install NVIDIA drivers: https://www.nvidia.com/drivers
- Install CUDA Toolkit: https://developer.nvidia.com/cuda-downloads
- Reinstall PyTorch with CUDA: `pip install torch torchvision --index-url https://download.pytorch.org/whl/cu121`

### Slow generation on CPU
- The system will work on CPU but will be 10-20x slower
- Strongly recommend using GPU for practical use

### Model download fails
- Check internet connection
- Model downloads from Hugging Face (~2GB)
- May take 5-10 minutes on first run

## Advanced Configuration

### Change Model Quality

Edit `model_generator.py`, line ~240:

```python
images = self.pipe(
    ai_prompt["prompt"],
    guidance_scale=15.0,      # Higher = more accurate to prompt (10-20)
    num_inference_steps=64,   # Higher = better quality (32-128)
    frame_size=256            # Higher = more detail (128-512)
).images
```

**Note:** Higher values = slower generation and more VRAM usage

## Cost Comparison

| Method | Cost per Model | Speed | Quality |
|--------|---------------|-------|---------|
| **Local GPU** | $0.00 | 30-60s | Good |
| Meshy AI | ~$0.50 | 60-180s | Excellent |
| Tripo AI | ~$0.30 | 30-60s | Very Good |

**Your GPU pays for itself after ~400 models!**

## Next Steps

1. Generate your first model
2. Import into Blender for refinement
3. Add textures and materials
4. Export for your game/project

Enjoy unlimited FREE 3D model generation! 🎉
