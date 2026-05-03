# Getting Started - 3D Model Generator

## Quick Start (5 minutes)

### Step 1: Install Dependencies
```bash
pip install -r requirements.txt
```

### Step 2: Choose Your Provider

You have **3 options**:

#### Option A: Meshy AI (Recommended - Best Quality)
✅ **200 FREE credits** (~20 models)  
✅ Professional quality  
✅ Works with any Python version  

1. Sign up at https://meshy.ai
2. Copy your API key
3. Edit `.env` file:
   ```
   MODEL_PROVIDER=meshy
   MESHY_API_KEY=msy_your_key_here
   ```

#### Option B: Tripo AI (Fast Generation)
✅ Free trial available  
✅ Very fast (30-60 seconds)  
✅ Works with any Python version  

1. Sign up at https://tripo3d.ai
2. Copy your API key
3. Edit `.env` file:
   ```
   MODEL_PROVIDER=tripo
   TRIPO_API_KEY=your_key_here
   ```

#### Option C: Local GPU (Free Forever)
⚠️ **Requires Python 3.10 or 3.11** (not 3.13)  
✅ Unlimited free generations  
✅ Completely private  
✅ Requires NVIDIA GPU (6GB+ VRAM)  

See `PYTHON_VERSION_ISSUE.md` if you have Python 3.13.

### Step 3: Start the Server
```bash
python app.py
```

You should see:
```
✅ GPU Detected: NVIDIA GeForce RTX 4060 Ti
   CUDA Version: 11.8
   GPU Memory: 16.0 GB
 * Running on http://127.0.0.1:5000
```

### Step 4: Generate Your First Model

1. Open http://localhost:5000 in your browser
2. Select your provider from the dropdown
3. Enter a prompt:
   - "muscular warrior with medieval armor"
   - "female character in casual jeans and t-shirt"
   - "sci-fi character with futuristic tech suit"
4. Click "Generate 3D Model"
5. Wait 1-3 minutes
6. Download your model!

## Example Prompts

### Fantasy Characters
- "muscular male warrior with heavy plate armor and sword"
- "female elf archer with leather armor and bow"
- "wizard in flowing robes with magical staff"

### Modern Characters
- "athletic male in casual hoodie and jeans"
- "business woman in formal suit"
- "teenager in streetwear clothing"

### Sci-Fi Characters
- "space marine in futuristic power armor"
- "cyberpunk hacker with tech implants"
- "alien creature with biomechanical features"

### Base Models (For Rigging)
- "neutral human male in T-pose, no clothing"
- "athletic female base mesh for animation"
- "stylized character base model"

## Understanding the Interface

### Provider Selection
- **Local GPU**: Uses your RTX 4060 Ti (requires Python 3.10/3.11)
- **Meshy AI**: Cloud service, best quality
- **Tripo AI**: Cloud service, fastest
- **Hugging Face**: 2D concept art only (free)

### Input Methods

**Text Prompt Tab:**
- Simple natural language input
- Best for quick iterations
- Example: "muscular warrior with armor"

**Advanced Tab:**
- Detailed control over:
  - Gender (Male/Female/Neutral)
  - Body Type (Slim/Athletic/Muscular/Heavy/Average)
  - Clothing Type (Casual/Formal/Fantasy/Sci-Fi/Medieval/None)
  - Skin Tone
  - Hair Style & Color
  - Pose
  - Accessories

### Download Formats

**From Cloud Providers (Meshy/Tripo):**
- `.glb` - Standard 3D format
- Compatible with Blender, Unity, Unreal Engine

**From Local GPU:**
- `.ply` - Point cloud format
- `.obj` - Mesh format (when available)
- Convert in Blender if needed

## Using Generated Models

### In Blender
1. Open Blender
2. File → Import → glTF 2.0 (.glb)
3. Select your downloaded model
4. Edit, texture, and export

### In Unity
1. Drag .glb file into Assets folder
2. Unity automatically imports
3. Add to scene and configure

### In Unreal Engine
1. Import as FBX (convert from .glb first)
2. Or use glTF import plugin
3. Set up materials and animations

## Troubleshooting

### "Python 3.13 compatibility issue"
- **Solution**: Use Meshy AI or Tripo AI
- **Or**: Downgrade to Python 3.10/3.11
- See `PYTHON_VERSION_ISSUE.md`

### "No GPU detected"
- Check NVIDIA drivers installed
- Verify with: `nvidia-smi`
- Use cloud providers as alternative

### "API key invalid"
- Double-check key in `.env` file
- Ensure no extra spaces
- Regenerate key if needed

### "Generation failed"
- Try simpler prompt
- Check internet connection (for cloud)
- Try different provider

## Cost Breakdown

| Provider | Free Credits | Cost After | Quality | Speed |
|----------|-------------|------------|---------|-------|
| **Meshy AI** | 200 credits (~20 models) | ~$0.50/model | Excellent | Fast |
| **Tripo AI** | Trial credits | ~$0.30/model | Very Good | Very Fast |
| **Local GPU** | Unlimited | $0.00 | Good | Medium |
| **Hugging Face** | Unlimited | $0.00 | 2D only | Fast |

## Tips for Best Results

### Prompt Writing
- Be specific about details
- Mention clothing style explicitly
- Specify pose if needed
- Include material descriptions

### Good Prompts
✅ "muscular male warrior with polished steel plate armor, red cape, holding longsword, heroic pose"
✅ "female cyberpunk hacker, neon jacket, tech goggles, casual stance"

### Poor Prompts
❌ "warrior" (too vague)
❌ "cool character" (unclear)

### Iteration Strategy
1. Start with cloud provider for quality
2. Test variations quickly
3. Refine best results
4. Use local GPU for final iterations (if available)

## Next Steps

1. ✅ Generate your first model
2. ✅ Import into Blender
3. ✅ Add textures and materials
4. ✅ Export for your project
5. ✅ Share your creations!

## Support

- **Python Issues**: See `PYTHON_VERSION_ISSUE.md`
- **GPU Setup**: See `SETUP_GPU.md`
- **Free Options**: See `FREE_OPTIONS.md`
- **Installation**: See `INSTALL_GUIDE.md`

Happy creating! 🎨
