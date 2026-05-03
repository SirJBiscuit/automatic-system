import { User, Shirt, Palette, Activity } from 'lucide-react';

const PromptBuilder = ({ prompt, onChange, onGenerate, loading }) => {
  const updateField = (field, value) => {
    onChange({ ...prompt, [field]: value });
  };

  return (
    <div className="space-y-6">
      <div>
        <label className="flex items-center gap-2 text-purple-200 font-semibold mb-2">
          <User className="w-4 h-4" />
          Gender
        </label>
        <select
          value={prompt.gender || 'neutral'}
          onChange={(e) => updateField('gender', e.target.value)}
          className="w-full px-4 py-2 bg-white/5 border border-white/20 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-purple-500"
        >
          <option value="male">Male</option>
          <option value="female">Female</option>
          <option value="neutral">Neutral</option>
        </select>
      </div>

      <div>
        <label className="flex items-center gap-2 text-purple-200 font-semibold mb-2">
          <Activity className="w-4 h-4" />
          Body Type
        </label>
        <select
          value={prompt.body_type || 'average'}
          onChange={(e) => updateField('body_type', e.target.value)}
          className="w-full px-4 py-2 bg-white/5 border border-white/20 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-purple-500"
        >
          <option value="slim">Slim</option>
          <option value="athletic">Athletic</option>
          <option value="average">Average</option>
          <option value="muscular">Muscular</option>
          <option value="petite">Petite</option>
          <option value="plus-size">Plus Size</option>
        </select>
      </div>

      <div>
        <label className="flex items-center gap-2 text-purple-200 font-semibold mb-2">
          <Shirt className="w-4 h-4" />
          Clothing Type
        </label>
        <select
          value={prompt.clothing_type || 'casual'}
          onChange={(e) => updateField('clothing_type', e.target.value)}
          className="w-full px-4 py-2 bg-white/5 border border-white/20 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-purple-500"
        >
          <option value="none">No Clothes (Base Model)</option>
          <option value="casual">Casual</option>
          <option value="formal">Formal</option>
          <option value="athletic">Athletic</option>
          <option value="fantasy">Fantasy</option>
          <option value="sci-fi">Sci-Fi</option>
          <option value="medieval">Medieval</option>
          <option value="modern">Modern</option>
          <option value="swimwear">Swimwear</option>
          <option value="traditional">Traditional</option>
        </select>
      </div>

      <div>
        <label className="flex items-center gap-2 text-purple-200 font-semibold mb-2">
          <Palette className="w-4 h-4" />
          Skin Tone
        </label>
        <select
          value={prompt.skin_tone || 'medium'}
          onChange={(e) => updateField('skin_tone', e.target.value)}
          className="w-full px-4 py-2 bg-white/5 border border-white/20 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-purple-500"
        >
          <option value="very-light">Very Light</option>
          <option value="light">Light</option>
          <option value="medium">Medium</option>
          <option value="tan">Tan</option>
          <option value="dark">Dark</option>
          <option value="very-dark">Very Dark</option>
        </select>
      </div>

      <div>
        <label className="text-purple-200 font-semibold mb-2 block">
          Hair Style
        </label>
        <input
          type="text"
          value={prompt.hair_style || ''}
          onChange={(e) => updateField('hair_style', e.target.value)}
          placeholder="e.g., short, long, curly, bald..."
          className="w-full px-4 py-2 bg-white/5 border border-white/20 rounded-lg text-white placeholder-purple-300/50 focus:outline-none focus:ring-2 focus:ring-purple-500"
        />
      </div>

      <div>
        <label className="text-purple-200 font-semibold mb-2 block">
          Hair Color
        </label>
        <input
          type="text"
          value={prompt.hair_color || ''}
          onChange={(e) => updateField('hair_color', e.target.value)}
          placeholder="e.g., black, blonde, red..."
          className="w-full px-4 py-2 bg-white/5 border border-white/20 rounded-lg text-white placeholder-purple-300/50 focus:outline-none focus:ring-2 focus:ring-purple-500"
        />
      </div>

      <div>
        <label className="text-purple-200 font-semibold mb-2 block">
          Pose
        </label>
        <input
          type="text"
          value={prompt.pose || 'T-pose'}
          onChange={(e) => updateField('pose', e.target.value)}
          placeholder="e.g., T-pose, standing, sitting..."
          className="w-full px-4 py-2 bg-white/5 border border-white/20 rounded-lg text-white placeholder-purple-300/50 focus:outline-none focus:ring-2 focus:ring-purple-500"
        />
      </div>

      <div>
        <label className="text-purple-200 font-semibold mb-2 block">
          Additional Details
        </label>
        <textarea
          value={prompt.custom_prompt || ''}
          onChange={(e) => updateField('custom_prompt', e.target.value)}
          placeholder="Any additional details about the character..."
          className="w-full h-24 px-4 py-2 bg-white/5 border border-white/20 rounded-lg text-white placeholder-purple-300/50 focus:outline-none focus:ring-2 focus:ring-purple-500"
        />
      </div>

      <button
        onClick={onGenerate}
        disabled={loading}
        className="w-full py-3 px-6 bg-gradient-to-r from-purple-600 to-pink-600 text-white font-bold rounded-lg hover:from-purple-700 hover:to-pink-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all shadow-lg"
      >
        Generate Prompt
      </button>
    </div>
  );
};

export default PromptBuilder;
