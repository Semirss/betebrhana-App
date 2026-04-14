import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ChevronLeft, Search, Bookmark, Download } from 'lucide-react';
import { hasDownloadedBook, downloadBook } from '../utils/storage';
import api from '../api';

export default function BookDetailsPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  
  const [book, setBook] = useState(null);
  const [loading, setLoading] = useState(true);
  
  const [isDownloaded, setIsDownloaded] = useState(false);
  const [isDownloading, setIsDownloading] = useState(false);
  const [actionLoading, setActionLoading] = useState(false);

  useEffect(() => {
    async function loadBookData() {
      try {
        setLoading(true);
        // The mobile app fetches all books and finds it, or caches it. We fetch the list:
        const { data } = await api.get('/books');
        const found = data.find(b => b.id === parseInt(id) || b.id === id);
        if (found) {
          setBook(found);
          const dlStatus = await hasDownloadedBook(found.id);
          setIsDownloaded(dlStatus);
        }
      } catch (err) {
        console.error("Failed to fetch book", err);
      } finally {
        setLoading(false);
      }
    }
    loadBookData();
  }, [id]);

  const handleDownload = async () => {
    try {
      setIsDownloading(true);
      await downloadBook(book.id, book);
      setIsDownloaded(true);
      alert('Book downloaded successfully for offline reading.');
    } catch (err) {
      alert('Failed to download book. Make sure you have an active rental first!');
    } finally {
      setIsDownloading(false);
    }
  };

  const handleRent = async () => {
    try {
      setActionLoading(true);
      await api.post('/books/rent', { bookId: book.id });
      alert("Success! You have rented the book.");
      // Read now immediately
      navigate(`/read/${book.id}`);
    } catch (err) {
      alert(err.response?.data?.error || "Error renting the book");
    } finally {
      setActionLoading(false);
    }
  };

  const handleQueue = async () => {
    try {
      setActionLoading(true);
      await api.post('/queue/add', { bookId: book.id });
      alert("You have joined the queue for this book!");
      window.location.reload();
    } catch (err) {
      alert(err.response?.data?.error || "Error joining queue");
    } finally {
      setActionLoading(false);
    }
  };

  if (loading) return <div className="min-h-screen pt-24 text-center">Loading...</div>;
  if (!book) return <div className="min-h-screen pt-24 text-center">Book not found.</div>;

  return (
    <div className="pt-12 pb-24 relative">
      <div className="flex justify-between items-center px-6 mb-8 relative z-10">
        <button onClick={() => navigate(-1)} className="p-3 rounded-full bg-white/80 backdrop-blur-md shadow-sm">
          <ChevronLeft size={20} />
        </button>
        <h2 className="text-xs font-bold tracking-[0.2em] text-zinc-600">BOOKS</h2>
        <button className="p-3 rounded-full bg-white/80 backdrop-blur-md shadow-sm">
          <Search size={20} />
        </button>
      </div>

      <div className="flex justify-center mb-8">
        <div className="relative w-48 aspect-[2/3] rounded-lg overflow-hidden shadow-2xl bg-zinc-100">
          {book.cover_image && <img src={book.cover_image} alt={book.title} className="w-full h-full object-cover" />}
          {isDownloaded && (
            <div className="absolute top-2 left-2 bg-blue-500 text-white p-1 rounded-sm shadow-md">
              <Bookmark size={16} fill="currentColor" />
            </div>
          )}
        </div>
      </div>

      <div className="px-6 text-center mb-8">
        <h1 className="text-2xl font-serif font-bold text-zinc-900 mb-2">{book.title}</h1>
        <p className="text-sm text-zinc-500 mb-2">
          {book.author} 
        </p>
        <p className="text-[10px] font-bold tracking-widest text-[#d8a892] uppercase mb-4">{book.file_type || 'BOOK'}</p>
        
        <div className="flex items-center justify-center gap-2 mb-8">
          <div className="flex text-yellow-400 text-sm">
            ★★★★★
          </div>
          <span className="text-sm font-bold text-zinc-700">4.8</span>
        </div>

        <div className="flex items-center justify-between gap-4">
          <div className="flex -space-x-2">
            {[1,2,3].map(i => (
              <div key={i} className="w-8 h-8 rounded-full border-2 border-white bg-zinc-200" />
            ))}
            <div className="w-8 h-8 rounded-full border-2 border-white bg-zinc-100 flex items-center justify-center text-[8px] font-bold">
              +{book.total_copies}
            </div>
          </div>
          
          <div className="flex-1">
            {book.userHasRental ? (
              <button onClick={() => navigate(`/read/${book.id}`)} className="w-full py-4 bg-teal-400 hover:bg-teal-500 text-white font-bold rounded-full shadow-lg transition-colors shadow-teal-400/30">
                Read Now
              </button>
            ) : book.queueInfo?.effectiveAvailable ? (
               <button onClick={handleRent} disabled={actionLoading} className="w-full py-4 bg-primary hover:bg-orange-600 text-white font-bold rounded-full shadow-lg transition-colors shadow-orange-400/30">
                Rent (Reserved)
              </button>
            ) : book.queueInfo?.userInQueue ? (
               <button disabled className="w-full py-4 bg-zinc-200 text-zinc-500 font-bold rounded-full">
                Position #{book.queueInfo?.userPosition} in Queue
              </button>
            ) : book.available_copies > 0 ? (
               <button onClick={handleRent} disabled={actionLoading} className="w-full py-4 bg-teal-400 hover:bg-teal-500 text-white font-bold rounded-full shadow-lg transition-colors shadow-teal-400/30">
                Rent Now
              </button>
            ) : (
               <button onClick={handleQueue} disabled={actionLoading} className="w-full py-4 bg-amber-400 hover:bg-amber-500 text-white font-bold rounded-full shadow-lg transition-colors shadow-amber-400/30">
                Join Queue
              </button>
            )}
          </div>

          {book.userHasRental && (
            <button 
              onClick={!isDownloaded ? handleDownload : undefined}
              disabled={isDownloading}
              className={`p-4 rounded-full border shadow-sm transition-colors ${
                isDownloaded 
                ? 'bg-blue-50 border-blue-200 text-blue-500' 
                : 'bg-white border-zinc-200 text-zinc-400 hover:text-zinc-600'
              }`}
            >
              {isDownloading ? <span className="animate-spin text-xl">◌</span> : (isDownloaded ? <Bookmark size={20} fill="currentColor" /> : <Download size={20} />)}
            </button>
          )}
        </div>
      </div>

      <div className="bg-white/80 backdrop-blur-md rounded-t-3xl p-8 shadow-[-0_0px_40px_rgba(0,0,0,0.05)] border-t border-white/50 min-h-[300px]">
        <div className="w-12 h-1 bg-zinc-200 rounded-full mx-auto mb-8"></div>
        <h3 className="text-lg font-serif font-bold mb-4 text-zinc-900">Synopsis</h3>
        <p className="text-sm text-zinc-500 leading-relaxed whitespace-pre-wrap">
          {book.description || "No description available for this book."}
        </p>
      </div>
    </div>
  );
}
