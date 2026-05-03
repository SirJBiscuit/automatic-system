from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field
from enum import Enum
import json


class ClothingType(str, Enum):
    NONE = "none"
    CASUAL = "casual"
    FORMAL = "formal"
    ATHLETIC = "athletic"
    FANTASY = "fantasy"
    SCIFI = "sci-fi"
    MEDIEVAL = "medieval"
    MODERN = "modern"
    SWIMWEAR = "swimwear"
    TRADITIONAL = "traditional"


class BodyType(str, Enum):
    SLIM = "slim"
    ATHLETIC = "athletic"
    AVERAGE = "average"
    MUSCULAR = "muscular"
    PETITE = "petite"
    PLUS_SIZE = "plus-size"
    CUSTOM = "custom"


class Gender(str, Enum):
    MALE = "male"
    FEMALE = "female"
    NEUTRAL = "neutral"


class ClothingItem(BaseModel):
    type: str = Field(description="Type of clothing item (shirt, pants, dress, armor, etc.)")
    color: Optional[str] = Field(default=None, description="Primary color")
    material: Optional[str] = Field(default=None, description="Material type (cotton, leather, metal, etc.)")
    style: Optional[str] = Field(default=None, description="Style descriptor")
    details: Optional[List[str]] = Field(default=None, description="Additional details")


class ModelPrompt(BaseModel):
    gender: Gender = Field(default=Gender.NEUTRAL)
    body_type: BodyType = Field(default=BodyType.AVERAGE)
    height: Optional[float] = Field(default=1.75, description="Height in meters")
    
    clothing_type: ClothingType = Field(default=ClothingType.CASUAL)
    clothing_items: Optional[List[ClothingItem]] = Field(default=None)
    
    hair_style: Optional[str] = Field(default=None)
    hair_color: Optional[str] = Field(default=None)
    
    skin_tone: Optional[str] = Field(default="medium")
    
    accessories: Optional[List[str]] = Field(default=None, description="Accessories like glasses, jewelry, etc.")
    
    pose: Optional[str] = Field(default="T-pose", description="Character pose")
    
    style_modifiers: Optional[List[str]] = Field(default=None, description="Style tags like 'realistic', 'stylized', 'low-poly'")
    
    custom_prompt: Optional[str] = Field(default=None, description="Free-form custom description")
    
    negative_prompt: Optional[str] = Field(default=None, description="What to avoid in generation")


class PromptGenerator:
    
    @staticmethod
    def generate_from_text(text: str) -> ModelPrompt:
        text_lower = text.lower()
        
        prompt = ModelPrompt()
        
        if "male" in text_lower and "female" not in text_lower:
            prompt.gender = Gender.MALE
        elif "female" in text_lower:
            prompt.gender = Gender.FEMALE
        
        if any(word in text_lower for word in ["no clothes", "naked", "nude", "bare", "unclothed"]):
            prompt.clothing_type = ClothingType.NONE
        elif any(word in text_lower for word in ["armor", "knight", "medieval", "chainmail"]):
            prompt.clothing_type = ClothingType.MEDIEVAL
        elif any(word in text_lower for word in ["suit", "formal", "business", "tuxedo"]):
            prompt.clothing_type = ClothingType.FORMAL
        elif any(word in text_lower for word in ["athletic", "sports", "gym", "workout"]):
            prompt.clothing_type = ClothingType.ATHLETIC
        elif any(word in text_lower for word in ["fantasy", "magic", "wizard", "robe"]):
            prompt.clothing_type = ClothingType.FANTASY
        elif any(word in text_lower for word in ["sci-fi", "futuristic", "cyberpunk", "tech"]):
            prompt.clothing_type = ClothingType.SCIFI
        elif any(word in text_lower for word in ["swimsuit", "bikini", "swim"]):
            prompt.clothing_type = ClothingType.SWIMWEAR
        
        if "muscular" in text_lower or "buff" in text_lower:
            prompt.body_type = BodyType.MUSCULAR
        elif "slim" in text_lower or "thin" in text_lower:
            prompt.body_type = BodyType.SLIM
        elif "athletic" in text_lower:
            prompt.body_type = BodyType.ATHLETIC
        elif "petite" in text_lower:
            prompt.body_type = BodyType.PETITE
        
        prompt.custom_prompt = text
        
        return prompt
    
    @staticmethod
    def generate_structured(params: Dict[str, Any]) -> ModelPrompt:
        return ModelPrompt(**params)
    
    @staticmethod
    def to_description(prompt: ModelPrompt) -> str:
        parts = []
        
        parts.append(f"A {prompt.gender.value} character")
        parts.append(f"with a {prompt.body_type.value} build")
        
        if prompt.height:
            parts.append(f"approximately {prompt.height}m tall")
        
        if prompt.clothing_type == ClothingType.NONE:
            parts.append("with no clothing")
        else:
            parts.append(f"wearing {prompt.clothing_type.value} attire")
        
        if prompt.clothing_items:
            items_desc = ", ".join([item.type for item in prompt.clothing_items])
            parts.append(f"including {items_desc}")
        
        if prompt.hair_style:
            hair_desc = f"{prompt.hair_color + ' ' if prompt.hair_color else ''}{prompt.hair_style} hair"
            parts.append(f"with {hair_desc}")
        
        if prompt.skin_tone:
            parts.append(f"{prompt.skin_tone} skin tone")
        
        if prompt.accessories:
            parts.append(f"wearing {', '.join(prompt.accessories)}")
        
        if prompt.pose and prompt.pose != "T-pose":
            parts.append(f"in a {prompt.pose} pose")
        
        if prompt.style_modifiers:
            parts.append(f"rendered in {', '.join(prompt.style_modifiers)} style")
        
        description = ", ".join(parts) + "."
        
        if prompt.custom_prompt:
            description += f" Additional details: {prompt.custom_prompt}"
        
        return description
    
    @staticmethod
    def to_ai_prompt(prompt: ModelPrompt) -> Dict[str, str]:
        main_prompt = PromptGenerator.to_description(prompt)
        
        negative_parts = ["low quality", "blurry", "distorted", "deformed"]
        if prompt.negative_prompt:
            negative_parts.append(prompt.negative_prompt)
        
        return {
            "prompt": main_prompt,
            "negative_prompt": ", ".join(negative_parts)
        }
    
    @staticmethod
    def get_presets() -> Dict[str, ModelPrompt]:
        return {
            "casual_male": ModelPrompt(
                gender=Gender.MALE,
                body_type=BodyType.AVERAGE,
                clothing_type=ClothingType.CASUAL,
                custom_prompt="casual male character in jeans and t-shirt"
            ),
            "formal_female": ModelPrompt(
                gender=Gender.FEMALE,
                body_type=BodyType.SLIM,
                clothing_type=ClothingType.FORMAL,
                custom_prompt="elegant female character in business suit"
            ),
            "fantasy_warrior": ModelPrompt(
                gender=Gender.MALE,
                body_type=BodyType.MUSCULAR,
                clothing_type=ClothingType.FANTASY,
                custom_prompt="muscular fantasy warrior with armor and sword"
            ),
            "scifi_character": ModelPrompt(
                gender=Gender.NEUTRAL,
                body_type=BodyType.ATHLETIC,
                clothing_type=ClothingType.SCIFI,
                custom_prompt="futuristic sci-fi character with tech suit"
            ),
            "base_model": ModelPrompt(
                gender=Gender.NEUTRAL,
                body_type=BodyType.AVERAGE,
                clothing_type=ClothingType.NONE,
                custom_prompt="base human model for rigging and animation"
            )
        }
