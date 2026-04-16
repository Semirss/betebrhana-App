import { useState, useEffect, useRef } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { readBookFile } from '../utils/storage';
import { ChevronLeft, Settings, Moon, Sun, Monitor, Type, Menu } from 'lucide-react';
import api from '../api';

export default function ReaderPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [blobUrl, setBlobUrl] = useState(null);
  const [textContent, setTextContent] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);
  
  // Reader Settings
  const [theme, setTheme] = useState('light'); // light, dark, sepia
  const [mode, setMode] = useState('scroll'); // scroll, slide
  const [fontSize, setFontSize] = useState(16);
  const [showSettings, setShowSettings] = useState(false);
  const [currentPage, setCurrentPage] = useState(1);
  const totalPages = useRef(1); // Mock total pages for text

  useEffect(() => {
    async function loadBook() {
      try {
        setLoading(true);
        // Try offline first
        try {
          const decryptedBuffer = await readBookFile(id);
          // Check if it's likely text
          const textDecoder = new TextDecoder('utf-8');
          const text = textDecoder.decode(decryptedBuffer);
          
          // Naive check if it's text or PDF
          if (text.substring(0, 5) === '%PDF-') {
            const blob = new Blob([decryptedBuffer], { type: 'application/pdf' });
            setBlobUrl(URL.createObjectURL(blob));
          } else {
            setTextContent(text);
            totalPages.current = Math.max(1, Math.ceil(text.length / 1500));
          }
        } catch (offlineErr) {
          // If not offline, try fetching text content directly if online
          const res = await api.get(`/books/${id}/download-test`);
          if (res.data?.book?.content) {
            setTextContent(res.data.book.content);
            totalPages.current = Math.max(1, Math.ceil(res.data.book.content.length / 1500));
          } else {
            throw new Error("No readable content found");
          }
        }
      } catch (err) {
        setError(err.message || 'Error loading book. Rent or download it first.');
      } finally {
        setLoading(false);
      }
    }
    
    loadBook();

    return () => {
      if (blobUrl) {
        URL.revokeObjectURL(blobUrl);
      }
    };
  }, [id, blobUrl]);

  // Handle theme classes
  const getThemeClass = () => {
    if (theme === 'dark') return 'bg-[#121212] text-zinc-300';
    if (theme === 'sepia') return 'bg-[#f4ecd8] text-[#5b4636]';
    return 'bg-white text-zinc-900';
  };

  const currentTextChunk = () => {
    if (!textContent) return '';
    if (mode === 'scroll') return textContent;
    
    const charsPerPage = window.innerWidth > 600 ? 2500 : 1500;
    const start = (currentPage - 1) * charsPerPage;
    return textContent.substring(start, start + charsPerPage);
  };

  return (
    <div className={`h-screen w-full flex flex-col relative transition-colors duration-300 ${getThemeClass()}`}>
      
      {/* Top Header — always visible */}
      <div className={`flex-shrink-0 px-6 py-3 flex justify-between items-center z-10 border-b ${
        theme === 'dark' ? 'border-zinc-800 bg-[#121212]' : 
        theme === 'sepia' ? 'border-amber-200 bg-[#f4ecd8]' : 
        'border-zinc-100 bg-white'
      }`}>
        <button 
          onClick={() => navigate(-1)} 
          className={`flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-bold transition-colors ${
            theme === 'dark' ? 'bg-zinc-800 hover:bg-zinc-700 text-zinc-200' : 
            'bg-zinc-100 hover:bg-zinc-200 text-zinc-700'
          }`}
        >
          <ChevronLeft size={18} /> Back
        </button>

        <button 
          onClick={() => setShowSettings(!showSettings)} 
          className={`flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-bold transition-colors ${
            showSettings 
              ? 'bg-[#53389e] text-white'
              : theme === 'dark' ? 'bg-zinc-800 hover:bg-zinc-700 text-zinc-200' 
              : 'bg-zinc-100 hover:bg-zinc-200 text-zinc-700'
          }`}
        >
          <Settings size={18} /> Settings
        </button>
      </div>

      {/* Settings Panel Backdrop */}
      {showSettings && (
        <div className={`absolute top-[60px] right-6 p-5 rounded-2xl shadow-2xl z-20 w-72 border ${
          theme === 'dark' ? 'bg-zinc-900 border-zinc-700' : 'bg-white border-zinc-200'
        }`}>
          <div className="flex flex-col gap-4">
            
            {/* Theme */}
            <div className="flex justify-between items-center">
              <span className="text-xs font-bold text-zinc-500 uppercase">Theme</span>
              <div className="flex gap-2">
                <button onClick={()=>setTheme('light')} className={`p-2 rounded-full bg-white border ${theme==='light'?'border-primary text-primary':'border-zinc-200 text-zinc-400'}`}><Sun size={14}/></button>
                <button onClick={()=>setTheme('sepia')} className={`p-2 rounded-full bg-[#f4ecd8] border ${theme==='sepia'?'border-primary text-primary':'border-amber-200 text-amber-700'}`}><Monitor size={14}/></button>
                <button onClick={()=>setTheme('dark')} className={`p-2 rounded-full bg-zinc-800 border ${theme==='dark'?'border-primary text-primary':'border-zinc-700 text-zinc-400'}`}><Moon size={14}/></button>
              </div>
            </div>

            {/* Mode */}
            <div className="flex justify-between items-center">
              <span className="text-xs font-bold text-zinc-500 uppercase">Read Mode</span>
              <div className="flex bg-zinc-100 dark:bg-zinc-800 rounded-lg p-1">
                <button onClick={()=>setMode('scroll')} className={`px-3 py-1 text-xs rounded-md ${mode==='scroll'?'bg-white dark:bg-zinc-700 shadow-sm font-bold':''}`}>Scroll</button>
                <button onClick={()=>setMode('slide')} className={`px-3 py-1 text-xs rounded-md ${mode==='slide'?'bg-white dark:bg-zinc-700 shadow-sm font-bold':''}`}>Slide</button>
              </div>
            </div>

            {/* Font Size */}
            <div className="flex justify-between items-center">
              <span className="text-xs font-bold text-zinc-500 uppercase">Font Size</span>
              <div className="flex items-center gap-3">
                <button onClick={()=>setFontSize(f => Math.max(12, f - 2))} className="p-1"><Type size={12}/></button>
                <span className="text-sm font-bold">{fontSize}</span>
                <button onClick={()=>setFontSize(f => Math.min(32, f + 2))} className="p-1"><Type size={18}/></button>
              </div>
            </div>

          </div>
        </div>
      )}

      {/* Reader Body */}
      <div 
        className="flex-1 flex flex-col items-center justify-start overflow-hidden relative w-full h-full"
        onClick={() => { if(showSettings) setShowSettings(false) }}
      >
        {loading && <div className="animate-spin text-4xl mt-32 text-primary">◌</div>}
        {error && <div className="text-red-400 p-8 text-center mt-32">{error}</div>}
        
        {blobUrl && !textContent && (
          <iframe 
            src={blobUrl} 
            className="w-full h-full border-none"
            title="Book Reader"
          />
        )}

        {textContent && (
          <div className={`w-full ${
            mode === 'scroll' ? 'overflow-y-auto' : 'overflow-hidden'
          }`} style={{ fontSize: `${fontSize}px`, lineHeight: 1.8 }}>
            <div className="whitespace-pre-wrap font-serif pt-10 pb-20 max-w-[900px] mx-auto px-10 md:px-20">
              {currentTextChunk()}
            </div>
            
            {mode === 'slide' && (
              <div className="absolute inset-y-0 w-1/3 left-0 z-0" onClick={() => setCurrentPage(p => Math.max(1, p - 1))}></div>
            )}
            {mode === 'slide' && (
              <div className="absolute inset-y-0 w-1/3 right-0 z-0" onClick={() => setCurrentPage(p => Math.min(totalPages.current, p + 1))}></div>
            )}
          </div>
        )}
      </div>

      {/* Footer / Pagination */}
      {textContent && mode === 'slide' && (
        <div className="h-12 flex justify-center items-center border-t border-zinc-200/20 text-xs font-bold font-mono tracking-widest relative z-10 bg-inherit">
          {currentPage} / {totalPages.current}
        </div>
      )}
    </div>
  );
}
