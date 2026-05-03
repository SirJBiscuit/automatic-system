"""
TripoSR Integration for 3D Model Generation
Provides high-quality textured 3D models from text prompts
"""

import torch
import numpy as np
from PIL import Image
import trimesh
from typing import Optional
import os

class TripoSRGenerator:
    """Generate 3D models using TripoSR"""
    
    def __init__(self, device='cuda'):
        self.device = device
        self.model = None
        self.sd_pipe = None
        
    def load_model(self):
        """Load TripoSR model"""
        try:
            print("🔄 Loading TripoSR model...")
            
            # Try to import TripoSR from local installation
            import sys
            model_path = "./models/TripoSR"
            if model_path not in sys.path:
                sys.path.insert(0, model_path)
            
            try:
                from tsr.system import TSR
                from tsr.utils import remove_background, resize_foreground
                
                print(f"  📁 Loading from: {model_path}")
                
                self.model = TSR.from_pretrained(
                    model_path,
                    config_name="config.yaml",
                    weight_name="model.ckpt",
                )
                self.model.renderer.set_chunk_size(8192)
                self.model.to(self.device)
                
                print("✅ TripoSR model loaded successfully!")
                return True
                
            except ImportError as e:
                print(f"⚠️  TripoSR import failed: {e}")
                print("  Trying alternative: Stable Diffusion for images only")
                return self._load_stable_diffusion()
                
        except Exception as e:
            print(f"❌ Error loading TripoSR: {e}")
            import traceback
            traceback.print_exc()
            return False
    
    def _load_stable_diffusion(self):
        """Load Stable Diffusion as fallback"""
        try:
            from diffusers import StableDiffusionPipeline
            
            print("🔄 Loading Stable Diffusion for image generation...")
            
            # Try multiple SD versions
            models_to_try = [
                "runwayml/stable-diffusion-v1-5",
                "stabilityai/stable-diffusion-2-1",
                "CompVis/stable-diffusion-v1-4"
            ]
            
            for model_name in models_to_try:
                try:
                    print(f"  Trying: {model_name}")
                    self.sd_pipe = StableDiffusionPipeline.from_pretrained(
                        model_name,
                        torch_dtype=torch.float16 if self.device == "cuda" else torch.float32,
                        safety_checker=None
                    ).to(self.device)
                    
                    print(f"✅ Stable Diffusion loaded: {model_name}")
                    return True
                except Exception as e:
                    print(f"  ⚠️  Failed: {e}")
                    continue
            
            print("❌ All Stable Diffusion models failed to load")
            return False
            
        except Exception as e:
            print(f"❌ Error loading Stable Diffusion: {e}")
            return False
    
    def generate(self, prompt: str, num_inference_steps: int = 50, guidance_scale: float = 7.5):
        """Generate 3D model from text prompt"""
        
        if self.model is None and self.sd_pipe is None:
            if not self.load_model():
                raise Exception("Failed to load model")
        
        # Step 1: Generate reference image
        print(f"🎨 Generating reference image from prompt: {prompt}")
        
        if self.sd_pipe:
            image = self.sd_pipe(
                prompt,
                num_inference_steps=num_inference_steps,
                guidance_scale=guidance_scale,
                height=512,
                width=512
            ).images[0]
        else:
            raise Exception("No image generation model available")
        
        # Step 2: Convert to 3D if TripoSR is available
        if self.model:
            print("🔄 Converting image to 3D mesh with TripoSR...")
            return self._image_to_3d(image)
        else:
            print("⚠️  TripoSR not available - returning reference image only")
            return None, image
    
    def _image_to_3d(self, image: Image.Image):
        """Convert image to 3D mesh using TripoSR"""
        try:
            from tsr.utils import remove_background, resize_foreground
            
            # Preprocess image
            image = remove_background(image)
            image = resize_foreground(image, 0.85)
            
            # Generate 3D
            with torch.no_grad():
                scene_codes = self.model([image], self.device)
                meshes = self.model.extract_mesh(scene_codes)
            
            return meshes[0], image
            
        except Exception as e:
            print(f"❌ Error converting to 3D: {e}")
            return None, image


class InstantMeshGenerator:
    """Generate 3D models using InstantMesh (multi-view approach)"""
    
    def __init__(self, device='cuda'):
        self.device = device
        self.model = None
        
    def load_model(self):
        """Load InstantMesh model"""
        print("⚠️  InstantMesh requires manual installation")
        print("   Visit: https://github.com/TencentARC/InstantMesh")
        return False
    
    def generate(self, prompt: str):
        """Generate 3D model"""
        raise NotImplementedError("InstantMesh not yet integrated")


def create_simple_mesh_from_image(image: Image.Image, output_path: str):
    """
    Create a simple textured plane mesh from an image
    This is a fallback when TripoSR is not available
    """
    import numpy as np
    
    # Create a simple plane
    vertices = np.array([
        [-1, -1, 0],
        [1, -1, 0],
        [1, 1, 0],
        [-1, 1, 0]
    ])
    
    faces = np.array([
        [0, 1, 2],
        [0, 2, 3]
    ])
    
    # Create UV coordinates
    uv = np.array([
        [0, 0],
        [1, 0],
        [1, 1],
        [0, 1]
    ])
    
    # Create mesh
    mesh = trimesh.Trimesh(vertices=vertices, faces=faces)
    
    # Save with texture
    material = trimesh.visual.material.SimpleMaterial(image=image)
    mesh.visual = trimesh.visual.TextureVisuals(uv=uv, material=material)
    
    mesh.export(output_path)
    return mesh
