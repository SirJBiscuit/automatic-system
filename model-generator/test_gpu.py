import torch
print(f"PyTorch version: {torch.__version__}")
print(f"CUDA available: {torch.cuda.is_available()}")
if torch.cuda.is_available():
    print(f"GPU: {torch.cuda.get_device_name(0)}")
    print(f"CUDA version: {torch.version.cuda}")

try:
    from diffusers import DiffusionPipeline
    print("✅ Diffusers imported successfully")
    
    print("\nTrying to load Shap-E model...")
    pipe = DiffusionPipeline.from_pretrained(
        "openai/shap-e",
        torch_dtype=torch.float16,
        trust_remote_code=True
    )
    print("✅ Model loaded successfully!")
except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
