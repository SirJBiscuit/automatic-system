import { Cloud, Cpu, Zap } from 'lucide-react';

const ProviderSelector = ({ providers, currentProvider, onProviderChange }) => {
  const getProviderIcon = (name) => {
    switch (name) {
      case 'meshy':
      case 'tripo':
        return <Cloud className="w-5 h-5" />;
      case 'local':
        return <Cpu className="w-5 h-5" />;
      default:
        return <Zap className="w-5 h-5" />;
    }
  };

  const handleProviderChange = async (provider) => {
    try {
      const response = await fetch('http://localhost:5000/api/provider', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ provider })
      });
      const data = await response.json();
      if (data.success) {
        onProviderChange(provider);
      }
    } catch (error) {
      console.error('Failed to change provider:', error);
    }
  };

  return (
    <div className="space-y-3">
      {Object.entries(providers).map(([key, info]) => (
        <button
          key={key}
          onClick={() => handleProviderChange(key)}
          className={`w-full p-4 rounded-lg border-2 transition-all text-left ${
            currentProvider === key
              ? 'border-purple-500 bg-purple-500/20'
              : 'border-white/10 bg-white/5 hover:border-white/30'
          }`}
        >
          <div className="flex items-start gap-3">
            <div className={`mt-1 ${currentProvider === key ? 'text-purple-400' : 'text-purple-300'}`}>
              {getProviderIcon(key)}
            </div>
            <div className="flex-1">
              <div className="flex items-center justify-between mb-1">
                <h3 className="font-bold text-white">{info.name}</h3>
                <div className="flex gap-2">
                  <span className="text-xs px-2 py-1 rounded bg-purple-500/30 text-purple-200">
                    {info.speed}
                  </span>
                  <span className="text-xs px-2 py-1 rounded bg-pink-500/30 text-pink-200">
                    {info.quality}
                  </span>
                </div>
              </div>
              <p className="text-sm text-purple-200">{info.description}</p>
              {info.requires_api_key && (
                <p className="text-xs text-yellow-400 mt-2">⚠️ Requires API key</p>
              )}
            </div>
          </div>
        </button>
      ))}
    </div>
  );
};

export default ProviderSelector;
