import { useState, useEffect } from 'react';
import { Wand2, Download, Settings, Sparkles, User, Shirt, Palette } from 'lucide-react';
import PromptBuilder from './components/PromptBuilder';
import ModelViewer from './components/ModelViewer';
import ProviderSelector from './components/ProviderSelector';

function App() {
  const [activeTab, setActiveTab] = useState('text');
  const [textPrompt, setTextPrompt] = useState('');
  const [structuredPrompt, setStructuredPrompt] = useState({});
  const [generatedPrompt, setGeneratedPrompt] = useState(null);
  const [modelResult, setModelResult] = useState(null);
  const [loading, setLoading] = useState(false);
  const [provider, setProvider] = useState('meshy');
  const [providers, setProviders] = useState({});

  useEffect(() => {
    fetchProviders();
  }, []);

  const fetchProviders = async () => {
    try {
      const response = await fetch('http://localhost:5000/api/providers');
      const data = await response.json();
      if (data.success) {
        setProviders(data.providers);
        setProvider(data.current);
      }
    } catch (error) {
      console.error('Failed to fetch providers:', error);
    }
  };

  const handleTextGenerate = async () => {
    setLoading(true);
    try {
      const response = await fetch('http://localhost:5000/api/generate/text', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text: textPrompt })
      });
      const data = await response.json();
      if (data.success) {
        setGeneratedPrompt(data);
        setStructuredPrompt(data.prompt);
      }
    } catch (error) {
      console.error('Failed to generate prompt:', error);
    }
    setLoading(false);
  };

  const handleStructuredGenerate = async () => {
    setLoading(true);
    try {
      const response = await fetch('http://localhost:5000/api/generate/structured', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(structuredPrompt)
      });
      const data = await response.json();
      if (data.success) {
        setGeneratedPrompt(data);
      }
    } catch (error) {
      console.error('Failed to generate prompt:', error);
    }
    setLoading(false);
  };

  const handleGenerateModel = async () => {
    setLoading(true);
    try {
      const response = await fetch('http://localhost:5000/api/generate/model', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(structuredPrompt)
      });
      const data = await response.json();
      if (data.success) {
        setModelResult(data);
        pollStatus(data.task_id);
      }
    } catch (error) {
      console.error('Failed to generate model:', error);
      setLoading(false);
    }
  };

  const pollStatus = async (taskId) => {
    const interval = setInterval(async () => {
      try {
        const response = await fetch(`http://localhost:5000/api/status/${taskId}`);
        const data = await response.json();
        
        if (data.success) {
          setModelResult(prev => ({ ...prev, ...data }));
          
          if (data.status === 'succeeded' || data.status === 'completed') {
            clearInterval(interval);
            setLoading(false);
          } else if (data.status === 'failed') {
            clearInterval(interval);
            setLoading(false);
          }
        }
      } catch (error) {
        console.error('Failed to check status:', error);
      }
    }, 3000);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900">
      <div className="container mx-auto px-4 py-8">
        <header className="text-center mb-12">
          <div className="flex items-center justify-center gap-3 mb-4">
            <Sparkles className="w-12 h-12 text-purple-400" />
            <h1 className="text-5xl font-bold text-white">3D Model Generator</h1>
          </div>
          <p className="text-xl text-purple-200">AI-Powered Character Creation with Clothing Options</p>
        </header>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          <div className="space-y-6">
            <div className="bg-white/10 backdrop-blur-lg rounded-2xl p-6 shadow-2xl border border-white/20">
              <div className="flex items-center gap-2 mb-6">
                <Settings className="w-6 h-6 text-purple-400" />
                <h2 className="text-2xl font-bold text-white">AI Provider</h2>
              </div>
              <ProviderSelector 
                providers={providers}
                currentProvider={provider}
                onProviderChange={setProvider}
              />
            </div>

            <div className="bg-white/10 backdrop-blur-lg rounded-2xl p-6 shadow-2xl border border-white/20">
              <div className="flex gap-4 mb-6">
                <button
                  onClick={() => setActiveTab('text')}
                  className={`flex-1 py-3 px-4 rounded-lg font-semibold transition-all ${
                    activeTab === 'text'
                      ? 'bg-purple-600 text-white shadow-lg'
                      : 'bg-white/5 text-purple-200 hover:bg-white/10'
                  }`}
                >
                  <Wand2 className="w-5 h-5 inline mr-2" />
                  Text Prompt
                </button>
                <button
                  onClick={() => setActiveTab('structured')}
                  className={`flex-1 py-3 px-4 rounded-lg font-semibold transition-all ${
                    activeTab === 'structured'
                      ? 'bg-purple-600 text-white shadow-lg'
                      : 'bg-white/5 text-purple-200 hover:bg-white/10'
                  }`}
                >
                  <Settings className="w-5 h-5 inline mr-2" />
                  Advanced
                </button>
              </div>

              {activeTab === 'text' ? (
                <div className="space-y-4">
                  <div>
                    <label className="block text-purple-200 font-semibold mb-2">
                      Describe your character:
                    </label>
                    <textarea
                      value={textPrompt}
                      onChange={(e) => setTextPrompt(e.target.value)}
                      placeholder="e.g., A muscular male warrior with medieval armor, or a female character in casual clothes..."
                      className="w-full h-32 px-4 py-3 bg-white/5 border border-white/20 rounded-lg text-white placeholder-purple-300/50 focus:outline-none focus:ring-2 focus:ring-purple-500"
                    />
                  </div>
                  <button
                    onClick={handleTextGenerate}
                    disabled={loading || !textPrompt}
                    className="w-full py-3 px-6 bg-gradient-to-r from-purple-600 to-pink-600 text-white font-bold rounded-lg hover:from-purple-700 hover:to-pink-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all shadow-lg"
                  >
                    Generate Prompt
                  </button>
                </div>
              ) : (
                <PromptBuilder
                  prompt={structuredPrompt}
                  onChange={setStructuredPrompt}
                  onGenerate={handleStructuredGenerate}
                  loading={loading}
                />
              )}
            </div>

            {generatedPrompt && (
              <div className="bg-white/10 backdrop-blur-lg rounded-2xl p-6 shadow-2xl border border-white/20">
                <h3 className="text-xl font-bold text-white mb-4">Generated Description</h3>
                <p className="text-purple-100 mb-6 leading-relaxed">{generatedPrompt.description}</p>
                <button
                  onClick={handleGenerateModel}
                  disabled={loading}
                  className="w-full py-3 px-6 bg-gradient-to-r from-green-600 to-emerald-600 text-white font-bold rounded-lg hover:from-green-700 hover:to-emerald-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all shadow-lg"
                >
                  {loading ? 'Generating 3D Model...' : 'Generate 3D Model'}
                </button>
              </div>
            )}
          </div>

          <div className="space-y-6">
            <ModelViewer result={modelResult} loading={loading} />
          </div>
        </div>
      </div>
    </div>
  );
}

export default App;
