import os
import requests
import time
from typing import Optional, Dict, Any
from abc import ABC, abstractmethod
from dotenv import load_dotenv
from prompt_generator import ModelPrompt, PromptGenerator

load_dotenv()


class ModelGeneratorBase(ABC):
    
    @abstractmethod
    def generate(self, prompt: ModelPrompt, quality_settings: Dict[str, Any] = None) -> Dict[str, Any]:
        pass
    
    @abstractmethod
    def check_status(self, task_id: str) -> Dict[str, Any]:
        pass


class MeshyAIGenerator(ModelGeneratorBase):
    
    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key or os.getenv("MESHY_API_KEY")
        self.base_url = "https://api.meshy.ai/v2"
        self.headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
    
    def generate(self, prompt: ModelPrompt, quality_settings: Dict[str, Any] = None) -> Dict[str, Any]:
        ai_prompt = PromptGenerator.to_ai_prompt(prompt)
        
        payload = {
            "mode": "preview",
            "prompt": ai_prompt["prompt"],
            "negative_prompt": ai_prompt["negative_prompt"],
            "art_style": "realistic" if "realistic" in (prompt.style_modifiers or []) else "auto",
            "ai_model": "meshy-4"
        }
        
        try:
            response = requests.post(
                f"{self.base_url}/text-to-3d",
                headers=self.headers,
                json=payload
            )
            response.raise_for_status()
            result = response.json()
            
            return {
                "success": True,
                "task_id": result.get("result"),
                "provider": "meshy",
                "status": "processing"
            }
        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "provider": "meshy"
            }
    
    def check_status(self, task_id: str) -> Dict[str, Any]:
        try:
            response = requests.get(
                f"{self.base_url}/text-to-3d/{task_id}",
                headers=self.headers
            )
            response.raise_for_status()
            result = response.json()
            
            return {
                "success": True,
                "status": result.get("status"),
                "progress": result.get("progress", 0),
                "model_url": result.get("model_urls", {}).get("glb"),
                "thumbnail_url": result.get("thumbnail_url"),
                "task_id": task_id
            }
        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }
    
    def refine_model(self, task_id: str) -> Dict[str, Any]:
        payload = {
            "preview_task_id": task_id
        }
        
        try:
            response = requests.post(
                f"{self.base_url}/text-to-3d/refine",
                headers=self.headers,
                json=payload
            )
            response.raise_for_status()
            result = response.json()
            
            return {
                "success": True,
                "task_id": result.get("result"),
                "status": "refining"
            }
        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }


class TripoAIGenerator(ModelGeneratorBase):
    
    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key or os.getenv("TRIPO_API_KEY")
        self.base_url = "https://api.tripo3d.ai/v2/openapi"
        self.headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
    
    def generate(self, prompt: ModelPrompt, quality_settings: Dict[str, Any] = None) -> Dict[str, Any]:
        ai_prompt = PromptGenerator.to_ai_prompt(prompt)
        
        payload = {
            "type": "text_to_model",
            "prompt": ai_prompt["prompt"],
            "negative_prompt": ai_prompt["negative_prompt"],
            "model_version": "v2.0-20240919"
        }
        
        try:
            response = requests.post(
                f"{self.base_url}/task",
                headers=self.headers,
                json=payload
            )
            response.raise_for_status()
            result = response.json()
            
            return {
                "success": True,
                "task_id": result["data"]["task_id"],
                "provider": "tripo",
                "status": "processing"
            }
        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "provider": "tripo"
            }
    
    def check_status(self, task_id: str) -> Dict[str, Any]:
        try:
            response = requests.get(
                f"{self.base_url}/task/{task_id}",
                headers=self.headers
            )
            response.raise_for_status()
            result = response.json()
            
            data = result["data"]
            return {
                "success": True,
                "status": data["status"],
                "progress": data.get("progress", 0),
                "model_url": data["output"].get("model") if data.get("output") else None,
                "task_id": task_id
            }
        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }


class LocalDiffusionGenerator(ModelGeneratorBase):
    
    def __init__(self):
        self.model_loaded = False
        self.pipe = None
        self.device = None
    
    def load_model(self):
        try:
            import torch
            from diffusers import ShapEPipeline
            
            self.device = "cuda" if torch.cuda.is_available() else "cpu"
            
            if self.device == "cpu":
                print("WARNING: No GPU detected. Generation will be very slow.")
            else:
                print(f"✅ Using GPU: {torch.cuda.get_device_name(0)}")
            
            print("📦 Loading Shap-E model... (first time: ~2GB download, 2-3 minutes)")
            
            self.pipe = ShapEPipeline.from_pretrained(
                "openai/shap-e",
                torch_dtype=torch.float16 if self.device == "cuda" else torch.float32
            )
            self.pipe = self.pipe.to(self.device)
            
            self.model_loaded = True
            print("✅ Model loaded successfully!")
            return True
            
        except ImportError as e:
            print(f"❌ Missing dependencies: {e}")
            print("Install with: pip install transformers diffusers accelerate")
            return False
        except Exception as e:
            print(f"❌ Failed to load model: {e}")
            import traceback
            traceback.print_exc()
            return False
    
    def generate(self, prompt: ModelPrompt, quality_settings: Dict[str, Any] = None, advanced_settings: Dict[str, Any] = None, progress_callback=None) -> Dict[str, Any]:
        if not self.model_loaded:
            print("🔄 Loading model for first time...")
            if not self.load_model():
                return {
                    "success": False,
                    "error": "Failed to load model. Check terminal for details.",
                    "provider": "local"
                }
        
        ai_prompt = PromptGenerator.to_ai_prompt(prompt)
        
        try:
            import torch
            from diffusers.utils import export_to_ply, export_to_obj
            
            # Use custom quality settings or defaults
            if quality_settings is None:
                quality_settings = {
                    'resolution': 512,
                    'steps': 128,
                    'guidance': 20.0
                }
            
            # Use advanced settings or defaults
            if advanced_settings is None:
                advanced_settings = {
                    'pose': 't-pose',
                    'style': 'realistic',
                    'export_formats': {'ply': True, 'obj': True},
                    'batch_generation': False,
                    'batch_count': 1
                }
            
            resolution = quality_settings.get('resolution', 512)
            steps = quality_settings.get('steps', 128)
            guidance = quality_settings.get('guidance', 20.0)
            
            # Enhance prompt with pose and style
            pose = advanced_settings.get('pose', 't-pose')
            style = advanced_settings.get('style', 'realistic')
            character_details = advanced_settings.get('character_details', {})
            
            enhanced_prompt = ai_prompt['prompt']
            if pose != 'custom':
                enhanced_prompt += f", in {pose} pose"
            enhanced_prompt += f", {style} style"
            
            # Add detailed character features to prompt
            detail_additions = []
            
            if character_details.get('anatomically_correct', True):
                detail_additions.append("anatomically correct proportions")
            
            # Hair details
            hair_detail = character_details.get('hair_detail', 'medium')
            if hair_detail == 'high':
                detail_additions.append("highly detailed hair with individual strands")
            elif hair_detail == 'medium':
                detail_additions.append("detailed styled hair")
            elif hair_detail == 'low':
                detail_additions.append("basic hair shape")
            
            # Eye details
            if character_details.get('detailed_eyes', True):
                detail_additions.append("detailed realistic eyeballs with reflections")
            if character_details.get('iris_detail', True):
                detail_additions.append("intricate iris patterns")
            if character_details.get('eyelashes', True):
                detail_additions.append("natural eyelashes")
            if character_details.get('eyebrows', True):
                detail_additions.append("defined eyebrows")
            
            # Makeup details
            if character_details.get('lipstick'):
                detail_additions.append("wearing lipstick")
            if character_details.get('lip_gloss'):
                detail_additions.append("glossy lips with shine")
            if character_details.get('eyeshadow'):
                detail_additions.append("eyeshadow makeup")
            if character_details.get('blush'):
                detail_additions.append("natural blush")
            if character_details.get('nail_polish'):
                detail_additions.append("painted fingernails with nail polish")
            if character_details.get('foundation'):
                detail_additions.append("smooth foundation makeup")
            
            # Hand and body details
            hand_detail = character_details.get('hand_detail', 'medium')
            if hand_detail == 'high':
                detail_additions.append("highly detailed hands with fingerprints and nail beds")
            elif hand_detail == 'medium':
                detail_additions.append("detailed hands and fingernails")
            
            if character_details.get('finger_nails', True):
                detail_additions.append("detailed fingernails")
            if character_details.get('muscle_definition', True):
                detail_additions.append("realistic muscle definition")
            if character_details.get('skin_pores'):
                detail_additions.append("visible skin pores and texture")
            if character_details.get('veins'):
                detail_additions.append("subtle visible veins")
            
            # Add all details to prompt
            if detail_additions:
                enhanced_prompt += ", " + ", ".join(detail_additions)
            
            # Get selected AI model
            ai_model = advanced_settings.get('ai_model', 'auto')
            
            # Auto-select best model based on prompt analysis
            if ai_model == 'auto':
                ai_model = self._auto_select_model(enhanced_prompt, character_details, style, resolution)
                print(f"🧠 AUTO-SELECT: Chose {ai_model.upper()} (best for your request)")
            
            print(f"🤖 Using AI Model: {ai_model.upper()}")
            print(f"🎨 Generating 3D model with prompt: {enhanced_prompt}")
            print(f"⚙️  Settings: {resolution}px, {steps} steps, guidance {guidance}")
            print(f"🎭 Style: {style}, Pose: {pose}")
            
            if progress_callback:
                progress_callback(10, "🔄 Loading AI model...")
            
            # Route to appropriate model
            if progress_callback:
                progress_callback(30, "🎨 Generating 3D mesh... (this may take 30-60 seconds)")
            
            if ai_model == 'triposr':
                output = self._generate_with_triposr(enhanced_prompt, resolution, steps, guidance, progress_callback)
            elif ai_model == 'instantmesh':
                output = self._generate_with_instantmesh(enhanced_prompt, resolution, steps, guidance, progress_callback)
            elif ai_model == 'point-e':
                output = self._generate_with_pointe(enhanced_prompt, resolution, steps, guidance, progress_callback)
            else:  # shap-e (default fallback)
                print(f"⏳ Estimated time: ~{int(30 * (resolution/256) * (steps/64))} seconds...")
                
                # Simulate progress during generation
                if progress_callback:
                    import threading
                    def simulate_progress():
                        for i in range(30, 90, 5):
                            time.sleep(2)
                            progress_callback(i, f"🎨 Generating mesh... {i}%")
                    
                    progress_thread = threading.Thread(target=simulate_progress)
                    progress_thread.daemon = True
                    progress_thread.start()
                
                output = self.pipe(
                    enhanced_prompt,
                    guidance_scale=guidance,
                    num_inference_steps=steps,
                    frame_size=resolution,
                    output_type="mesh"
                )
                
                if progress_callback:
                    progress_callback(90, "💾 Saving model files...")
            
            timestamp = int(time.time())
            output_dir = "outputs"
            os.makedirs(output_dir, exist_ok=True)
            
            base_name = f"model_{timestamp}"
            export_formats = advanced_settings.get('export_formats', {
                'ply': True, 
                'obj': True, 
                'glb': False, 
                'fbx': False
            })
            exported_files = []
            
            print(f"💾 Saving model in multiple formats...")
            
            # Save PLY (primary format)
            if export_formats.get('ply', True):
                ply_path = os.path.join(output_dir, f"{base_name}.ply")
                with open(ply_path, 'wb') as f:
                    output.export(f, 'ply')
                exported_files.append(('ply', ply_path))
                primary_file = ply_path
                print(f"  ✅ Saved .ply file")
                raise ValueError("No mesh generated from model")
            
            print(f"✅ Model generated successfully! {len(exported_files)} formats exported")
            
            # Return primary file (first exported)
            primary_file = exported_files[0][1] if exported_files else None
            
            return {
                "success": True,
                "task_id": primary_file,
                "provider": "local",
                "status": "succeeded",
                "model_url": f"/outputs/{os.path.basename(primary_file)}",
                "obj_url": f"/outputs/{base_name}.obj" if export_formats.get('obj') else None,
                "exported_files": [f"/outputs/{os.path.basename(f[1])}" for f in exported_files],
                "message": f"✅ 3D model generated! {len(exported_files)} formats ready for download."
            }
            
        except Exception as e:
            print(f"❌ Generation error: {e}")
            import traceback
            traceback.print_exc()
            return {
                "success": False,
                "error": f"Generation failed: {str(e)}",
                "provider": "local"
            }
    
    def _generate_with_triposr(self, prompt: str, resolution: int, steps: int, guidance: float, progress_callback=None):
        """Generate using TripoSR - Best balance with textures"""
        print("⏳ Using TripoSR mode (10-20 seconds)...")
        
        try:
            # Try to use TripoSR integration
            from triposr_integration import TripoSRGenerator
            
            if progress_callback:
                progress_callback(40, "🎨 Loading TripoSR model...")
            
            triposr = TripoSRGenerator(device=self.device)
            
            if progress_callback:
                progress_callback(50, "🖼️ Generating high-quality reference image...")
            
            mesh, image = triposr.generate(
                prompt=prompt,
                num_inference_steps=min(steps, 50),
                guidance_scale=guidance
            )
            
            if progress_callback:
                progress_callback(80, "✨ Converting to 3D mesh...")
            
            if mesh:
                print("✅ TripoSR generated textured 3D model!")
                return mesh
            else:
                print("⚠️  TripoSR returned image only, using Shap-E for mesh")
                # Save the reference image for user
                if image:
                    image_path = f"outputs/reference_{int(time.time())}.png"
                    image.save(image_path)
                    print(f"💾 Saved reference image: {image_path}")
                
                # Fall back to Shap-E with better settings
                return self.pipe(
                    prompt,
                    guidance_scale=guidance * 1.5,
                    num_inference_steps=min(steps, 128),
                    frame_size=min(resolution, 512),
                    output_type="mesh"
                )
            
        except ImportError:
            print("⚠️  TripoSR not installed, using enhanced Shap-E")
            return self.pipe(
                prompt,
                guidance_scale=guidance * 1.5,
                num_inference_steps=min(steps, 128),
                frame_size=min(resolution, 512),
                output_type="mesh"
            )
        except Exception as e:
            print(f"⚠️  TripoSR error: {e}")
            print("  Falling back to enhanced Shap-E")
            import traceback
            traceback.print_exc()
            return self.pipe(
                prompt,
                guidance_scale=guidance * 1.5,
                num_inference_steps=min(steps, 128),
                frame_size=min(resolution, 512),
                output_type="mesh"
            )
    
    def _generate_with_instantmesh(self, prompt: str, resolution: int, steps: int, guidance: float, progress_callback=None):
        """Generate using InstantMesh - High quality (currently using optimized Shap-E)"""
        print("⏳ Using InstantMesh mode (60-90 seconds)...")
        print("⚠️  InstantMesh integration in progress - using ultra-optimized Shap-E")
        # Use Shap-E with maximum quality settings
        return self.pipe(
            prompt,
            guidance_scale=min(guidance * 1.3, 30.0),  # Boost guidance
            num_inference_steps=min(steps, 128),  # Cap for performance
            frame_size=min(resolution, 512),  # Cap resolution
            output_type="mesh"
        )
    
    def _generate_with_pointe(self, prompt: str, resolution: int, steps: int, guidance: float, progress_callback=None):
        """Generate using Point-E - Stylized models"""
        print("⏳ Using Point-E mode (15 seconds)...")
        print("⚠️  Point-E integration in progress - using stylized Shap-E")
        # Use Shap-E with settings optimized for stylized output
        return self.pipe(
            prompt + ", stylized, artistic",
            guidance_scale=guidance * 0.8,  # Lower guidance for creativity
            num_inference_steps=min(steps, 64),
            frame_size=min(resolution, 384),
            output_type="mesh"
        )
    
    def _auto_select_model(self, prompt: str, character_details: dict, style: str, resolution: int) -> str:
        """Intelligently select the best AI model based on prompt complexity and requirements"""
        
        prompt_lower = prompt.lower()
        
        # Count complexity indicators
        detail_count = 0
        if character_details.get('detailed_eyes'): detail_count += 1
        if character_details.get('lipstick') or character_details.get('lip_gloss'): detail_count += 1
        if character_details.get('nail_polish'): detail_count += 1
        if character_details.get('hair_detail') == 'high': detail_count += 2
        if character_details.get('hand_detail') == 'high': detail_count += 2
        if character_details.get('skin_pores'): detail_count += 1
        
        # Check for complexity keywords
        complex_keywords = ['detailed', 'realistic', 'intricate', 'professional', 'high quality', 'anatomically correct']
        simple_keywords = ['simple', 'basic', 'quick', 'preview', 'concept', 'rough']
        stylized_keywords = ['cartoon', 'anime', 'stylized', 'artistic', 'low-poly', 'pixel']
        
        complexity_score = sum(1 for keyword in complex_keywords if keyword in prompt_lower)
        simplicity_score = sum(1 for keyword in simple_keywords if keyword in prompt_lower)
        stylized_score = sum(1 for keyword in stylized_keywords if keyword in prompt_lower)
        
        # Decision logic
        total_complexity = detail_count + complexity_score
        
        # InstantMesh for very high detail requests
        if total_complexity >= 5 or resolution >= 768:
            print(f"  📊 Analysis: High complexity ({total_complexity} indicators) → InstantMesh")
            return 'instantmesh'
        
        # Point-E for stylized/artistic
        if stylized_score >= 2 or style in ['cartoon', 'anime', 'low-poly', 'pixel']:
            print(f"  📊 Analysis: Stylized request ({stylized_score} indicators) → Point-E")
            return 'point-e'
        
        # Shap-E for simple/quick previews
        if simplicity_score >= 2 or (total_complexity == 0 and resolution <= 256):
            print(f"  📊 Analysis: Simple request → Shap-E (fast)")
            return 'shap-e'
        
        # TripoSR as default (best balance)
        print(f"  📊 Analysis: Balanced request ({total_complexity} details) → TripoSR")
        return 'triposr'
    
    def check_status(self, task_id: str) -> Dict[str, Any]:
        if os.path.exists(task_id):
            return {
                "success": True,
                "status": "succeeded",
                "model_url": f"/outputs/{os.path.basename(task_id)}",
                "message": "✅ 3D model generated successfully! Download below."
            }
        return {
            "success": False,
            "error": "Model file not found"
        }


class HuggingFaceGenerator(ModelGeneratorBase):
    
    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key or os.getenv("HUGGINGFACE_TOKEN", "")
        self.base_url = "https://api-inference.huggingface.co/models"
        self.headers = {
            "Authorization": f"Bearer {self.api_key}" if self.api_key else "",
            "Content-Type": "application/json"
        }
    
    def generate(self, prompt: ModelPrompt, quality_settings: Dict[str, Any] = None) -> Dict[str, Any]:
        ai_prompt = PromptGenerator.to_ai_prompt(prompt)
        
        models_to_try = [
            "stabilityai/stable-diffusion-xl-base-1.0",
            "runwayml/stable-diffusion-v1-5",
            "CompVis/stable-diffusion-v1-4"
        ]
        
        payload = {
            "inputs": ai_prompt["prompt"] + " 3D render, high quality, detailed"
        }
        
        for model in models_to_try:
            try:
                response = requests.post(
                    f"{self.base_url}/{model}",
                    headers=self.headers,
                    json=payload,
                    timeout=60
                )
                
                if response.status_code == 503:
                    continue
                
                if response.status_code == 200:
                    output_path = f"outputs/model_{int(time.time())}.png"
                    os.makedirs("outputs", exist_ok=True)
                    
                    with open(output_path, 'wb') as f:
                        f.write(response.content)
                    
                    return {
                        "success": True,
                        "task_id": output_path,
                        "provider": "huggingface",
                        "status": "completed",
                        "thumbnail_url": f"/outputs/{os.path.basename(output_path)}",
                        "message": "Generated 2D concept art. For 3D models, please use Meshy AI or Tripo AI (free trials available)."
                    }
                    
            except Exception as e:
                continue
        
        return {
            "success": False,
            "error": "Free 3D generation is currently unavailable. Please try: 1) Meshy AI (https://meshy.ai - free trial), 2) Tripo AI (https://tripo3d.ai - free trial), or 3) Use the generated 2D concept as reference.",
            "provider": "huggingface",
            "help_url": "https://meshy.ai"
        }
    
    def check_status(self, task_id: str) -> Dict[str, Any]:
        return {
            "success": True,
            "status": "completed",
            "thumbnail_url": task_id
        }


class ModelGeneratorFactory:
    
    @staticmethod
    def create(provider: str = "meshy") -> ModelGeneratorBase:
        providers = {
            "meshy": MeshyAIGenerator,
            "tripo": TripoAIGenerator,
            "huggingface": HuggingFaceGenerator,
            "local": LocalDiffusionGenerator
        }
        
        generator_class = providers.get(provider.lower())
        if not generator_class:
            raise ValueError(f"Unknown provider: {provider}")
        
        return generator_class()
    
    @staticmethod
    def get_available_providers() -> Dict[str, Dict[str, Any]]:
        import torch
        has_gpu = torch.cuda.is_available() if 'torch' in dir() else False
        
        providers = {
            "local": {
                "name": "Local GPU (Your Server)" if has_gpu else "Local CPU (Slow)",
                "description": f"Generate on your {'GPU' if has_gpu else 'CPU'} - 100% FREE, unlimited use!",
                "requires_api_key": False,
                "speed": "medium" if has_gpu else "very slow",
                "quality": "good",
                "cost": "100% FREE",
                "gpu_available": has_gpu
            },
            "huggingface": {
                "name": "Hugging Face (2D Concept Art)",
                "description": "Free 2D character concept generation - Use as reference for 3D modeling",
                "requires_api_key": False,
                "speed": "fast",
                "quality": "good",
                "cost": "100% FREE"
            },
            "meshy": {
                "name": "Meshy AI (Cloud 3D)",
                "description": "High-quality 3D models - Free trial with 200 credits",
                "requires_api_key": True,
                "speed": "fast",
                "quality": "high",
                "cost": "Free trial available"
            },
            "tripo": {
                "name": "Tripo AI (Fast Cloud 3D)",
                "description": "Fast 3D generation - Free trial available",
                "requires_api_key": True,
                "speed": "very fast",
                "quality": "medium-high",
                "cost": "Free trial available"
            }
        }
        
        return providers
