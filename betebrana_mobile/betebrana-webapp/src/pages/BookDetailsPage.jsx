import { useState, useEffect } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { ChevronLeft, Search, Bookmark, Download, Star, ArrowRight } from 'lucide-react';
import { hasDownloadedBook, downloadBook } from '../utils/storage';
import api from '../api';

const PH = 'https://placehold.co/300x450/e8e8e8/aaaaaa?text=No+Cover';
const onErr = (e) => { e.target.onerror = null; e.target.src = PH; };

export default function BookDetailsPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  
  const [book, setBook] = useState(null);
  const [loading, setLoading] = useState(true);
  const [recommendedBooks, setRecommendedBooks] = useState([]);
  
  const [isDownloaded, setIsDownloaded] = useState(false);
  const [isDownloading, setIsDownloading] = useState(false);
  const [actionLoading, setActionLoading] = useState(false);

  useEffect(() => {
    async function loadBookData() {
      try {
        setLoading(true);
        const { data } = await api.get('/books');
        const found = data.find(b => b.id === parseInt(id) || b.id === id);
        if (found) {
          setBook(found);
          const dlStatus = await hasDownloadedBook(found.id);
          setIsDownloaded(dlStatus);
        }
        
        // Grab some recommendations
        setRecommendedBooks(data.filter(b => b.id !== parseInt(id) && b.id !== id).slice(0, 5));

      } catch (err) {
        console.error("Failed to fetch book", err);
      } finally {
        setLoading(false);
      }
    }
    loadBookData();
    window.scrollTo(0, 0);
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

  if (loading) return <div className="min-h-screen pt-32 text-center text-zinc-500 bg-[#FDFBF7]">Loading Book Data...</div>;
  if (!book) return <div className="min-h-screen pt-32 text-center text-zinc-500 bg-[#FDFBF7]">Book not found.</div>;

  return (
    <div className="bg-[#FDFBF7] min-h-screen pt-24 md:pt-32 pb-24">
      <div className="max-w-[1200px] mx-auto px-6 md:px-8">
        
        {/* Top Navbar Details */}
        <div className="flex justify-between items-center mb-10">
          <button onClick={() => navigate(-1)} className="flex items-center gap-2 px-4 py-2 bg-white rounded-full border border-zinc-200 hover:bg-zinc-50 transition-colors shadow-sm text-sm font-bold text-zinc-700">
            <ChevronLeft size={18} /> Back
          </button>
          <button onClick={() => navigate('/search')} className="p-3 bg-white rounded-full border border-zinc-200 shadow-sm text-zinc-500 hover:text-[#53389e] transition-colors">
            <Search size={18} />
          </button>
        </div>

        {/* Main Content Split Layout */}
        <div className="flex flex-col lg:flex-row gap-12 lg:gap-20 mb-24">
          
          {/* Left Column - Image & Actions */}
          <div className="w-full lg:w-[360px] flex-shrink-0 flex flex-col items-center lg:items-stretch">
            <div className="w-[140px] sm:w-[280px] lg:w-full aspect-[3/4] rounded-2xl overflow-hidden shadow-2xl border border-zinc-200 bg-white relative mb-8">
              <img src={book.cover_image || PH} onError={onErr} alt={book.title} className="w-full h-full object-cover" />
             
            </div>

            {/* Action Buttons for Desktop (Shows here on Large screens, and centered on Mobile) */}
            <div className="w-full max-w-[280px] lg:max-w-none flex flex-col gap-4">
              {book.userHasRental ? (
                <button onClick={() => navigate(`/read/${book.id}`)} className="w-full py-4 bg-[#bbf7d0] hover:bg-[#86efac] text-[#166534] font-bold rounded-xl shadow-sm transition-all border border-[#4ade80]">
                  Read Now
                </button>
              ) : book.queueInfo?.effectiveAvailable ? (
                 <button onClick={handleRent} disabled={actionLoading} className="w-full py-4 bg-[#53389e] hover:bg-[#432c81] text-white font-bold rounded-xl shadow-lg transition-all shadow-purple-900/20">
                  Rent (Reserved for you)
                </button>
              ) : book.queueInfo?.userInQueue ? (
                 <button disabled className="w-full py-4 bg-zinc-200 text-zinc-500 font-bold rounded-xl border border-zinc-300">
                  Position #{book.queueInfo?.userPosition} in Queue
                </button>
              ) : book.available_copies > 0 ? (
                 <button onClick={handleRent} disabled={actionLoading} className="w-full py-4 bg-[#53389e] hover:bg-[#432c81] text-white font-bold rounded-xl shadow-lg transition-all shadow-purple-900/20">
                  Borrow Book
                </button>
              ) : (
                 <button onClick={handleQueue} disabled={actionLoading} className="w-full py-4 bg-orange-100 hover:bg-orange-200 text-orange-800 font-bold border border-orange-200 rounded-xl shadow-sm transition-all">
                  Join Waiting Queue
                </button>
              )}

              {book.userHasRental && (
                <button 
                  onClick={!isDownloaded ? handleDownload : undefined}
                  disabled={isDownloading}
                  className={`w-full py-4 rounded-xl flex items-center justify-center gap-3 font-bold transition-all border ${
                    isDownloaded 
                    ? 'bg-blue-50 border-blue-200 text-blue-600' 
                    : 'bg-white border-zinc-200 text-zinc-600 hover:text-zinc-900 shadow-sm hover:shadow'
                  }`}
                >
                  {isDownloading ? (
                    <><span className="animate-spin text-xl">◌</span> Downloading...</>
                  ) : isDownloaded ? (
                    <><Bookmark size={18} fill="currentColor" /> Saved for Offline</>
                  ) : (
                    <><Download size={18} /> Download for Offline</>
                  )}
                </button>
              )}
            </div>
          </div>

          {/* Right Column - Book Info */}
          <div className="flex-1 lg:pt-4 text-center lg:text-left">
            <h1 className="text-3xl md:text-5xl font-serif font-bold text-zinc-900 mb-4 leading-tight">{book.title}</h1>
            <p className="text-xl text-zinc-500 mb-8 font-medium">By <span className="text-zinc-800">{book.author}</span></p>
            
            <div className="flex flex-wrap items-center justify-center lg:justify-start gap-4 md:gap-8 mb-10">
              <div className="flex items-center gap-2 bg-white px-4 py-2 rounded-full border border-zinc-200 shadow-sm">
                <Star fill="#53389e" color="#53389e" size={16} /> 
                <span className="font-bold text-zinc-800 text-sm">4.8 <span className="text-zinc-400 font-normal">/ 5.0</span></span>
              </div>
              <div className="bg-[#ede9fe] text-[#53389e] px-4 py-2 rounded-full text-xs font-bold uppercase tracking-wider border border-[#ddd6fe]">
                {book.category || 'Literature'}
              </div>
              <div className="flex items-center gap-2 bg-white px-4 py-2 rounded-full border border-zinc-200 shadow-sm">
                <div className={`w-2 h-2 rounded-full ${book.available_copies > 0 ? "bg-green-500" : "bg-orange-500"}`}></div>
                <span className="text-sm font-bold text-zinc-700">
                  {book.available_copies > 0 ? `${book.available_copies} Copies Available` : `0 Copies (Queue)`}
                </span>
              </div>
            </div>

            <div className="bg-white rounded-3xl p-8 md:p-10 shadow-lg border border-zinc-100 relative">
              <div className="absolute top-0 left-10 w-16 h-1 bg-[#53389e] rounded-b-lg"></div>
              <h3 className="text-xl font-serif font-bold mb-6 text-zinc-900">Synopsis</h3>
              <div className="text-zinc-500 leading-relaxed space-y-4 text-[15px]">
                {book.description ? (
                  book.description.split('\n').filter(p => p.trim() !== '').map((para, i) => (
                    <p key={i}>{para}</p>
                  ))
                ) : (
                  <p>No detailed synopsis available for this book yet. Dive in and explore the pages yourself!</p>
                )}
              </div>
            </div>
          </div>
        </div>

        {/* Similar Books Section */}
        {recommendedBooks.length > 0 && (
          <div className="border-t border-zinc-200/60 pt-20">
            <div className="flex justify-between items-end mb-10">
              <div>
                <h2 className="text-2xl font-serif font-bold text-zinc-900 tracking-tight">More Books You Might Like</h2>
              </div>
              <Link to="/search" className="hidden md:flex items-center gap-2 px-6 py-2.5 bg-white border border-zinc-200 hover:bg-zinc-50 text-zinc-700 rounded-full text-sm font-bold transition-colors">
                View All <ArrowRight size={16} />
              </Link>
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-6">
              {recommendedBooks.map(rec => (
                <Link to={`/book/${rec.id}`} key={rec.id} className="group">
                  <div className="aspect-[3/4] rounded-2xl overflow-hidden shadow-lg border border-zinc-100 mb-4 bg-zinc-100 relative">
                    <img src={rec.cover_image || PH} onError={onErr} alt={rec.title} className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500" />
                    <div className="absolute inset-x-0 bottom-0 p-3 bg-gradient-to-t from-black/60 to-transparent opacity-0 group-hover:opacity-100 transition-opacity flex justify-center">
                      <div className="w-full py-2 bg-[#53389e] hover:bg-[#432c81] text-white text-[10px] uppercase tracking-wider font-bold rounded-lg shadow-lg transform translate-y-2 group-hover:translate-y-0 transition-all flex items-center justify-center">
                        Details
                      </div>
                    </div>
                  </div>
                  <h4 className="text-sm font-bold text-zinc-900 mb-1 leading-snug truncate" title={rec.title}>{rec.title}</h4>
                  <p className="text-[10px] text-zinc-500 uppercase tracking-widest truncate">{rec.author}</p>
                </Link>
              ))}
            </div>
          </div>
        )}

      </div>
    </div>
  );
}
