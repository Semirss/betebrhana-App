import { useState, useEffect } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { ChevronLeft, Search, Bookmark, Download, Star, ArrowRight } from 'lucide-react';
import { hasDownloadedBook, downloadBook } from '../utils/storage';
import api from '../api';

const PH = 'https://placehold.co/300x450/ede9fe/53389e?text=No+Cover';
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
      alert('Book downloaded for offline reading.');
    } catch {
      alert('Failed to download. Make sure you have an active rental first!');
    } finally { setIsDownloading(false); }
  };

  const handleRent = async () => {
    try {
      setActionLoading(true);
      await api.post('/books/rent', { bookId: book.id });
      alert("Success! You have rented this book.");
      navigate(`/read/${book.id}`);
    } catch (err) {
      alert(err.response?.data?.error || "Error renting the book");
    } finally { setActionLoading(false); }
  };

  const handleQueue = async () => {
    try {
      setActionLoading(true);
      await api.post('/queue/add', { bookId: book.id });
      alert("You have joined the queue for this book!");
      window.location.reload();
    } catch (err) {
      alert(err.response?.data?.error || "Error joining queue");
    } finally { setActionLoading(false); }
  };

  if (loading) return <div className="min-h-screen pt-32 text-center text-zinc-500 bg-[#FDFBF7]">Loading Book…</div>;
  if (!book) return <div className="min-h-screen pt-32 text-center text-zinc-500 bg-[#FDFBF7]">Book not found.</div>;

  const primaryAction = book.userHasRental ? (
    <button onClick={() => navigate(`/read/${book.id}`)}
      className="flex-1 py-4 bg-[#20d9c0] hover:bg-[#17b8a6] text-white font-bold rounded-full shadow-lg shadow-teal-400/30 transition-all text-[15px]">
      Read Now
    </button>
  ) : book.queueInfo?.effectiveAvailable ? (
    <button onClick={handleRent} disabled={actionLoading}
      className="flex-1 py-4 bg-[#20d9c0] hover:bg-[#17b8a6] text-white font-bold rounded-full shadow-lg shadow-teal-400/30 transition-all text-[15px]">
      {actionLoading ? 'Please wait…' : 'Rent (Reserved)'}
    </button>
  ) : book.queueInfo?.userInQueue ? (
    <button disabled
      className="flex-1 py-4 bg-zinc-200 text-zinc-500 font-bold rounded-full text-[15px]">
      #{book.queueInfo?.userPosition} in Queue
    </button>
  ) : book.available_copies > 0 ? (
    <button onClick={handleRent} disabled={actionLoading}
      className="flex-1 py-4 bg-[#20d9c0] hover:bg-[#17b8a6] text-white font-bold rounded-full shadow-lg shadow-teal-400/30 transition-all text-[15px]">
      {actionLoading ? 'Please wait…' : 'Borrow Book'}
    </button>
  ) : (
    <button onClick={handleQueue} disabled={actionLoading}
      className="flex-1 py-4 bg-amber-400 hover:bg-amber-500 text-white font-bold rounded-full shadow-lg shadow-amber-400/30 transition-all text-[15px]">
      {actionLoading ? 'Please wait…' : 'Join Queue'}
    </button>
  );

  return (
    /* Outer container – gradient header fades into white, matching the reference design */
    <div className="min-h-screen bg-[#FDFBF7]">

      {/* Gradient hero band */}
      <div className="w-full bg-gradient-to-b from-[#e8f0fe] via-[#f0eafd] to-[#FDFBF7] pt-24 md:pt-32 pb-24">
        <div className="max-w-[720px] mx-auto px-6">

          {/* Top bar */}
          <div className="flex justify-between items-center mb-10">
            <button onClick={() => navigate(-1)}
              className="w-10 h-10 flex items-center justify-center bg-white/80 hover:bg-white backdrop-blur-sm rounded-full shadow-sm border border-zinc-200 text-zinc-600 transition-all">
              <ChevronLeft size={20} />
            </button>
            <span className="text-xs font-bold tracking-[0.2em] text-zinc-500 uppercase">Book Details</span>
            <button onClick={() => navigate('/search')}
              className="w-10 h-10 flex items-center justify-center bg-white/80 hover:bg-white backdrop-blur-sm rounded-full shadow-sm border border-zinc-200 text-zinc-600 transition-all">
              <Search size={18} />
            </button>
          </div>

          {/* Book cover — centered like the reference */}
          <div className="flex justify-center mb-8">
            <div className="relative w-[190px] sm:w-[220px] aspect-[2/3] rounded-2xl overflow-hidden shadow-2xl border border-white/60">
              <img src={book.cover_image || PH} onError={onErr} alt={book.title} className="w-full h-full object-cover" />
              {isDownloaded && (
                <div className="absolute top-3 left-3 bg-[#53389e] text-white p-1.5 rounded-lg shadow-md">
                  <Bookmark size={14} fill="currentColor" />
                </div>
              )}
            </div>
          </div>

          {/* Title, author, category, stars — center aligned */}
          <div className="text-center mb-8">
            <h1 className="text-2xl sm:text-3xl font-serif font-bold text-zinc-900 mb-2 leading-snug">{book.title}</h1>
            <p className="text-zinc-500 text-[15px] mb-2">
              {book.author}
              {book.file_type && <span className="text-zinc-400"> ({book.file_type.toUpperCase()})</span>}
            </p>
            {(book.category) && (
              <p className="text-xs font-bold tracking-[0.15em] text-[#d8a892] uppercase mb-4">{book.category}</p>
            )}

            {/* Stars */}
            <div className="flex items-center justify-center gap-2 mb-2">
              {[1,2,3,4].map(i => <Star key={i} size={18} fill="#f59e0b" color="#f59e0b" />)}
              <Star size={18} fill="#d1d5db" color="#d1d5db" />
              <span className="text-sm font-bold text-zinc-700 ml-1">4.8</span>
            </div>

            {/* Available copies badge */}
            <div className="inline-flex items-center gap-1.5 bg-white/80 border border-zinc-200 px-3 py-1.5 rounded-full text-xs font-bold text-zinc-600 shadow-sm mt-1">
              <div className={`w-2 h-2 rounded-full ${book.available_copies > 0 ? 'bg-green-400' : 'bg-orange-400'}`} />
              {book.available_copies > 0 ? `${book.available_copies} copies available` : 'All copies borrowed — join queue'}
            </div>
          </div>

          {/* Action row — avatars + primary CTA + bookmark */}
          <div className="flex items-center gap-4 mb-2">
            {/* Placeholder reader avatars */}
            <div className="flex items-center flex-shrink-0">
              {[0, 1, 2].map(i => (
                <div key={i} className="w-9 h-9 rounded-full border-2 border-white bg-gradient-to-br from-[#53389e]/60 to-[#9b82ff]/60 -ml-2 first:ml-0 shadow-sm" />
              ))}
              <span className="ml-2 text-xs font-bold text-zinc-500">+{book.total_copies || 0}</span>
            </div>

            {/* Primary action */}
            {primaryAction}

            {/* Bookmark / download */}
            <button
              onClick={book.userHasRental && !isDownloaded ? handleDownload : undefined}
              disabled={isDownloading}
              className={`w-12 h-12 flex-shrink-0 flex items-center justify-center rounded-full border-2 transition-all ${
                isDownloaded
                  ? 'bg-[#53389e] border-[#53389e] text-white'
                  : 'bg-white border-zinc-200 text-zinc-400 hover:border-[#53389e] hover:text-[#53389e]'
              }`}
            >
              {isDownloading
                ? <span className="animate-spin text-sm">◌</span>
                : <Bookmark size={18} fill={isDownloaded ? 'currentColor' : 'none'} />
              }
            </button>
          </div>
        </div>
      </div>

      {/* Synopsis — white sheet below gradient, matching the bottom-sheet style */}
      <div className="max-w-[720px] mx-auto px-6 -mt-8 relative z-10 pb-20">
        <div className="bg-white rounded-3xl shadow-lg border border-zinc-100 p-8">
          {/* Drag-handle decorative element */}
          <div className="w-10 h-1 bg-zinc-200 rounded-full mx-auto mb-8" />
          <h3 className="text-lg font-serif font-bold text-zinc-900 mb-4">Synopsis</h3>
          <div className="text-zinc-500 leading-relaxed space-y-4 text-[15px]">
            {book.description
              ? book.description.split('\n').filter(p => p.trim()).map((para, i) => <p key={i}>{para}</p>)
              : <p>No synopsis available for this book yet. Dive in and start reading!</p>
            }
          </div>
        </div>

        {/* More books you might like */}
        {recommendedBooks.length > 0 && (
          <div className="mt-14">
            <div className="flex justify-between items-end mb-6">
              <h2 className="text-xl font-serif font-bold text-zinc-900">You Might Also Like</h2>
              <Link to="/search" className="flex items-center gap-1.5 text-sm font-bold text-[#53389e] hover:underline">
                View all <ArrowRight size={14} />
              </Link>
            </div>
            <div className="grid grid-cols-5 gap-4">
              {recommendedBooks.map(rec => (
                <Link to={`/book/${rec.id}`} key={rec.id} className="group">
                  <div className="aspect-[2/3] rounded-xl overflow-hidden shadow-md border border-zinc-100 mb-3 bg-zinc-100 relative">
                    <img src={rec.cover_image || PH} onError={onErr} alt={rec.title} className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500" />
                    <div className="absolute inset-x-0 bottom-0 p-2.5 bg-gradient-to-t from-black/60 to-transparent opacity-0 group-hover:opacity-100 transition-opacity">
                      <div className="w-full py-1.5 bg-[#20d9c0] text-white text-[9px] uppercase tracking-wider font-bold rounded-lg flex items-center justify-center">
                        Borrow
                      </div>
                    </div>
                  </div>
                  <h4 className="text-xs font-bold text-zinc-800 truncate leading-snug" title={rec.title}>{rec.title}</h4>
                  <p className="text-[10px] text-zinc-400 uppercase tracking-wider truncate mt-0.5">{rec.author}</p>
                </Link>
              ))}
            </div>
          </div>
        )}
      </div>

    </div>
  );
}
