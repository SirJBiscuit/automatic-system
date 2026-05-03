# 🆓 100% FREE 3D Model Generator

A completely free AI-powered 3D character model generator with advanced prompt input system for creating characters with or without clothing.

## ⚠️ Important: Python Version

**If you have Python 3.13:** Local GPU generation is not yet supported due to library compatibility. Use Meshy AI or Tripo AI instead (200 free credits available).

**For local GPU:** Use Python 3.10 or 3.11. See `PYTHON_VERSION_ISSUE.md` for details.

## ✨ Features

- **🆓 Completely FREE**: No API keys, no signup, no payment required
- **🤖 Powered by Hugging Face**: Uses open-source AI models
- **⚡ Zero Setup**: Works immediately out of the box

- **Flexible Prompt Input**:
  - Text-based prompts (natural language)
  - Structured form with detailed options
  - Preset templates for quick start

- **Clothing Options**:
  - No clothes (base model)
  - Casual, Formal, Athletic
  - Fantasy, Sci-Fi, Medieval
  - Swimwear, Traditional, and more

- **Character Customization**:
  - Gender (Male, Female, Neutral)
  - Body types (Slim, Athletic, Muscular, etc.)
  - Skin tones
  - Hair styles and colors
  - Poses and accessories

## Setup

### 1. Install Python Dependencies

```bash
pip install -r requirements.txt
```

### 2. Install Node.js Dependencies

```bash
npm install
```

### 3. Run the Application (No Configuration Needed!)

**Start the server:**
```bash
python app.py
```

The app will open at `http://localhost:5000`

**That's it!** No frontend build needed, no API keys, just run and use!

## Usage

### Text Prompt Mode

Simply describe your character in natural language:

```
A muscular male warrior with medieval armor and a sword
```

```
A female character in casual clothes, jeans and t-shirt
```

```
A sci-fi character with futuristic tech suit, no helmet
```

### Advanced Mode

Use the structured form to specify:
- Gender and body type
- Clothing type and style
- Skin tone and hair
- Pose and accessories
- Additional custom details

### Generating Models

1. Create your prompt (text or structured)
2. Click "Generate Prompt" to preview the description
3. Click "Generate 3D Model" to start AI generation
4. Wait for the model to process (usually 1-3 minutes)
5. Download the .glb file when ready
6. (Meshy only) Optionally refine for higher quality

## Why This is 100% Free

- **No Signup**: Start generating immediately
- **No Hidden Costs**: Completely free forever
- **Open Source**: Built on open-source AI models

## Examples

### Base Model (No Clothes)
```json
{
  "gender": "neutral",
  "body_type": "average",
  "clothing_type": "none",
  "custom_prompt": "base human model for rigging"
}
```

### Fantasy Warrior
```json
{
  "gender": "male",
  "body_type": "muscular",
  "clothing_type": "fantasy",
  "custom_prompt": "warrior with plate armor and sword"
}
```

### Casual Character
```json
{
  "gender": "female",
  "body_type": "slim",
  "clothing_type": "casual",
  "custom_prompt": "young woman in jeans and hoodie"
}
```

## Output Format

Generated models are in `.glb` format (GL Transmission Format), compatible with:
- Blender
- Unity
- Unreal Engine
- Three.js
- Most 3D software

## Troubleshooting

**Model Loading**: First generation may take 1-2 minutes as the AI model loads on Hugging Face servers

**Generation Fails**: The free Hugging Face API may have rate limits during peak times - just wait a minute and try again

**Slow Generation**: Free AI generation takes 1-3 minutes - this is normal for free services

## License

MIT License - Feel free to use for personal or commercial projects
