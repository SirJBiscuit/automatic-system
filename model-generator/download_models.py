"""
Download AI models for 3D generation
Run this script to download TripoSR and other models
"""

import os
from huggingface_hub import hf_hub_download, snapshot_download
import torch

def download_triposr():
    """Download TripoSR model from HuggingFace"""
    print("=" * 60)
    print("🚀 Downloading TripoSR Model")
    print("=" * 60)
    print()
    print("📦 Model: stabilityai/TripoSR")
    print("📊 Size: ~2GB")
    print("⏱️  Time: 5-10 minutes (depending on internet speed)")
    print()
    
    try:
        print("🔄 Starting download...")
        
        # Download the entire TripoSR repository
        model_path = snapshot_download(
            repo_id="stabilityai/TripoSR",
            local_dir="./models/TripoSR",
            local_dir_use_symlinks=False
        )
        
        print()
        print("✅ TripoSR downloaded successfully!")
        print(f"📁 Location: {model_path}")
        print()
        return model_path
        
    except Exception as e:
        print(f"❌ Error downloading TripoSR: {e}")
        print()
        print("💡 Troubleshooting:")
        print("   1. Check your internet connection")
        print("   2. Make sure you have ~3GB free disk space")
        print("   3. Try running: pip install --upgrade huggingface_hub")
        return None

def download_stable_diffusion():
    """Download Stable Diffusion 2.1 for image generation"""
    print("=" * 60)
    print("🎨 Downloading Stable Diffusion 2.1")
    print("=" * 60)
    print()
    print("📦 Model: stabilityai/stable-diffusion-2-1")
    print("📊 Size: ~5GB")
    print("⏱️  Time: 10-15 minutes")
    print()
    
    try:
        from diffusers import StableDiffusionPipeline
        
        print("🔄 Starting download...")
        
        # This will download and cache the model
        pipe = StableDiffusionPipeline.from_pretrained(
            "stabilityai/stable-diffusion-2-1",
            torch_dtype=torch.float16 if torch.cuda.is_available() else torch.float32,
            safety_checker=None
        )
        
        print()
        print("✅ Stable Diffusion downloaded successfully!")
        print("📁 Cached in: ~/.cache/huggingface/")
        print()
        return True
        
    except Exception as e:
        print(f"❌ Error downloading Stable Diffusion: {e}")
        return False

def check_disk_space():
    """Check available disk space"""
    import shutil
    
    total, used, free = shutil.disk_usage(".")
    free_gb = free // (2**30)
    
    print("💾 Disk Space Check:")
    print(f"   Free space: {free_gb} GB")
    
    if free_gb < 10:
        print("   ⚠️  Warning: Less than 10GB free. Models need ~8GB total.")
        return False
    else:
        print("   ✅ Sufficient space available")
        return True

def main():
    print()
    print("╔════════════════════════════════════════════════════════╗")
    print("║         3D Model Generator - Model Downloader         ║")
    print("╚════════════════════════════════════════════════════════╝")
    print()
    
    # Check disk space
    if not check_disk_space():
        response = input("\n⚠️  Low disk space. Continue anyway? (y/n): ")
        if response.lower() != 'y':
            print("❌ Download cancelled.")
            return
    
    print()
    print("📋 What to download:")
    print("   1. TripoSR only (~2GB) - For 3D mesh generation")
    print("   2. Stable Diffusion only (~5GB) - For image generation")
    print("   3. Both (~7GB) - Full setup (RECOMMENDED)")
    print("   4. Cancel")
    print()
    
    choice = input("Enter your choice (1-4): ").strip()
    
    print()
    
    if choice == "1":
        download_triposr()
    elif choice == "2":
        download_stable_diffusion()
    elif choice == "3":
        print("🚀 Downloading both models...")
        print()
        triposr_ok = download_triposr()
        if triposr_ok:
            download_stable_diffusion()
    elif choice == "4":
        print("❌ Download cancelled.")
        return
    else:
        print("❌ Invalid choice.")
        return
    
    print()
    print("=" * 60)
    print("🎉 Download Complete!")
    print("=" * 60)
    print()
    print("📝 Next Steps:")
    print("   1. Restart your Flask server")
    print("   2. Generate a model with Auto-Select")
    print("   3. Enjoy high-quality textured 3D models!")
    print()

if __name__ == "__main__":
    main()
