from flask import Flask, request, jsonify, send_from_directory, render_template
from flask_cors import CORS
import os
from prompt_generator import PromptGenerator, ModelPrompt
from model_generator import ModelGeneratorFactory

app = Flask(__name__, static_folder='dist', template_folder='templates')
CORS(app)

generator = None
current_provider = os.getenv("MODEL_PROVIDER", "local")

try:
    import torch
    if torch.cuda.is_available():
        print(f"✅ GPU Detected: {torch.cuda.get_device_name(0)}")
        print(f"   CUDA Version: {torch.version.cuda}")
        print(f"   GPU Memory: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.1f} GB")
    else:
        print("⚠️  No GPU detected - will use CPU (slower)")
except (ImportError, OSError) as e:
    print("⚠️  GPU libraries not fully installed")
    print("   For local GPU generation, install CUDA from: https://developer.nvidia.com/cuda-downloads")
    print("   Or use cloud providers (Meshy AI, Tripo AI) instead")


@app.route('/api/providers', methods=['GET'])
def get_providers():
    providers = ModelGeneratorFactory.get_available_providers()
    return jsonify({
        "success": True,
        "providers": providers,
        "current": current_provider
    })


@app.route('/api/provider', methods=['POST'])
def set_provider():
    global generator, current_provider
    data = request.json
    provider = data.get('provider', 'meshy')
    
    try:
        generator = ModelGeneratorFactory.create(provider)
        current_provider = provider
        return jsonify({
            "success": True,
            "provider": provider
        })
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 400


@app.route('/api/presets', methods=['GET'])
def get_presets():
    presets = PromptGenerator.get_presets()
    return jsonify({
        "success": True,
        "presets": {
            name: prompt.model_dump() for name, prompt in presets.items()
        }
    })


@app.route('/api/generate/text', methods=['POST'])
def generate_from_text():
    data = request.json
    text = data.get('text', '')
    
    if not text:
        return jsonify({
            "success": False,
            "error": "Text prompt is required"
        }), 400
    
    prompt = PromptGenerator.generate_from_text(text)
    
    return jsonify({
        "success": True,
        "prompt": prompt.model_dump(),
        "description": PromptGenerator.to_description(prompt)
    })


@app.route('/api/generate/structured', methods=['POST'])
def generate_from_structured():
    data = request.json
    
    try:
        prompt = PromptGenerator.generate_structured(data)
        return jsonify({
            "success": True,
            "prompt": prompt.model_dump(),
            "description": PromptGenerator.to_description(prompt)
        })
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 400


import threading
import queue

# Global progress tracking
generation_progress = {}
progress_queue = queue.Queue()

@app.route('/api/generate/model', methods=['POST'])
def generate_model():
    global generator
    
    if generator is None:
        generator = ModelGeneratorFactory.create(current_provider)
    
    data = request.json
    
    try:
        # Extract quality and advanced settings if provided
        quality_settings = data.pop('quality_settings', None)
        advanced_settings = data.pop('advanced_settings', None)
        
        prompt = ModelPrompt(**data)
        
        # Generate task ID
        import time
        task_id = f"task_{int(time.time())}"
        generation_progress[task_id] = {"progress": 0, "status": "starting", "message": "Initializing..."}
        
        # Progress callback function
        def update_progress(progress, message):
            generation_progress[task_id] = {
                "progress": progress,
                "status": "processing",
                "message": message
            }
        
        # Run generation in background thread
        def generate_async():
            result = generator.generate(
                prompt, 
                quality_settings=quality_settings, 
                advanced_settings=advanced_settings,
                progress_callback=update_progress
            )
            generation_progress[task_id] = {
                "progress": 100,
                "status": "completed" if result.get("success") else "failed",
                "result": result
            }
        
        thread = threading.Thread(target=generate_async)
        thread.start()
        
        return jsonify({
            "success": True,
            "task_id": task_id,
            "message": "Generation started"
        })
    except Exception as e:
        return jsonify({
            "success": False,
            "error": str(e)
        }), 400

@app.route('/api/progress/<task_id>', methods=['GET'])
def get_progress(task_id):
    """Get real-time progress for a generation task"""
    if task_id in generation_progress:
        progress_data = generation_progress[task_id]
        
        # If completed, return the full result
        if progress_data.get("status") in ["completed", "failed"]:
            result = progress_data.get("result", {})
            return jsonify({
                "success": True,
                "progress": 100,
                "status": progress_data["status"],
                **result
            })
        
        return jsonify({
            "success": True,
            "progress": progress_data.get("progress", 0),
            "status": progress_data.get("status", "processing"),
            "message": progress_data.get("message", "Generating...")
        })
    
    return jsonify({
        "success": False,
        "error": "Task not found"
    }), 404


@app.route('/api/status/<task_id>', methods=['GET'])
def check_status(task_id):
    global generator
    
    if generator is None:
        return jsonify({
            "success": False,
            "error": "No generator initialized"
        }), 400
    
    result = generator.check_status(task_id)
    return jsonify(result)


@app.route('/api/refine/<task_id>', methods=['POST'])
def refine_model(task_id):
    global generator
    
    if generator is None or current_provider != "meshy":
        return jsonify({
            "success": False,
            "error": "Refine only available with Meshy AI"
        }), 400
    
    result = generator.refine_model(task_id)
    return jsonify(result)


@app.route('/outputs/<path:filename>')
def serve_output(filename):
    return send_from_directory('outputs', filename)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/<path:path>')
def serve(path):
    if os.path.exists(os.path.join(app.static_folder, path)):
        return send_from_directory(app.static_folder, path)
    return render_template('index.html')


if __name__ == '__main__':
    os.makedirs('outputs', exist_ok=True)
    app.run(debug=True, host='0.0.0.0', port=5000)
