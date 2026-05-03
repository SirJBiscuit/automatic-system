import { Download, Loader2, CheckCircle, XCircle } from 'lucide-react';

const ModelViewer = ({ result, loading }) => {
  const getStatusColor = (status) => {
    switch (status) {
      case 'succeeded':
      case 'completed':
        return 'text-green-400';
      case 'failed':
        return 'text-red-400';
      case 'processing':
      case 'refining':
        return 'text-yellow-400';
      default:
        return 'text-purple-400';
    }
  };

  const getStatusIcon = (status) => {
    switch (status) {
      case 'succeeded':
      case 'completed':
        return <CheckCircle className="w-6 h-6" />;
      case 'failed':
        return <XCircle className="w-6 h-6" />;
      default:
        return <Loader2 className="w-6 h-6 animate-spin" />;
    }
  };

  return (
    <div className="bg-white/10 backdrop-blur-lg rounded-2xl p-6 shadow-2xl border border-white/20 h-full">
      <h2 className="text-2xl font-bold text-white mb-6">3D Model Preview</h2>

      {!result && !loading && (
        <div className="flex flex-col items-center justify-center h-96 text-purple-300">
          <div className="w-32 h-32 mb-4 rounded-full bg-white/5 flex items-center justify-center">
            <svg className="w-16 h-16" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4" />
            </svg>
          </div>
          <p className="text-lg">Your 3D model will appear here</p>
          <p className="text-sm mt-2 text-purple-400">Create a prompt and generate a model to get started</p>
        </div>
      )}

      {loading && !result?.status && (
        <div className="flex flex-col items-center justify-center h-96">
          <Loader2 className="w-16 h-16 text-purple-400 animate-spin mb-4" />
          <p className="text-purple-200 text-lg">Initializing generation...</p>
        </div>
      )}

      {result && (
        <div className="space-y-6">
          <div className="bg-white/5 rounded-lg p-4 border border-white/10">
            <div className="flex items-center justify-between mb-2">
              <span className="text-purple-200 font-semibold">Status</span>
              <div className={`flex items-center gap-2 ${getStatusColor(result.status)}`}>
                {getStatusIcon(result.status)}
                <span className="capitalize">{result.status || 'Processing'}</span>
              </div>
            </div>
            
            {result.progress !== undefined && (
              <div className="mt-4">
                <div className="flex justify-between text-sm text-purple-300 mb-2">
                  <span>Progress</span>
                  <span>{result.progress}%</span>
                </div>
                <div className="w-full bg-white/10 rounded-full h-2">
                  <div
                    className="bg-gradient-to-r from-purple-600 to-pink-600 h-2 rounded-full transition-all duration-500"
                    style={{ width: `${result.progress}%` }}
                  />
                </div>
              </div>
            )}
          </div>

          {result.thumbnail_url && (
            <div className="bg-white/5 rounded-lg p-4 border border-white/10">
              <h3 className="text-purple-200 font-semibold mb-3">Preview</h3>
              <img
                src={result.thumbnail_url}
                alt="Model preview"
                className="w-full rounded-lg"
              />
            </div>
          )}

          {result.model_url && (
            <div className="space-y-3">
              <a
                href={result.model_url}
                download
                className="flex items-center justify-center gap-2 w-full py-3 px-6 bg-gradient-to-r from-green-600 to-emerald-600 text-white font-bold rounded-lg hover:from-green-700 hover:to-emerald-700 transition-all shadow-lg"
              >
                <Download className="w-5 h-5" />
                Download 3D Model (.glb)
              </a>

              {result.provider === 'meshy' && result.status === 'succeeded' && (
                <button
                  onClick={() => {
                    fetch(`http://localhost:5000/api/refine/${result.task_id}`, {
                      method: 'POST'
                    });
                  }}
                  className="w-full py-3 px-6 bg-gradient-to-r from-purple-600 to-pink-600 text-white font-bold rounded-lg hover:from-purple-700 hover:to-pink-700 transition-all shadow-lg"
                >
                  Refine Model (Higher Quality)
                </button>
              )}
            </div>
          )}

          {result.task_id && (
            <div className="bg-white/5 rounded-lg p-3 border border-white/10">
              <p className="text-xs text-purple-300">
                Task ID: <span className="font-mono">{result.task_id}</span>
              </p>
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default ModelViewer;
