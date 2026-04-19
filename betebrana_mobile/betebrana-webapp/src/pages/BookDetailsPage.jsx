import { useState, useEffect } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { ChevronLeft, Search, Bookmark, Download, Star, ArrowRight } from 'lucide-react';
import { hasDownloadedBook, downloadBook } from '../utils/storage';
import api from '../api';
import { useLanguage } from '../context/LanguageContext';

const PH = 'https://placehold.co/300x450/ede9fe/53389e?text=No+Cover';
const onErr = (e) => { e.target.onerror = null; e.target.src = PH; };

export default function BookDetailsPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { t } = useLanguage();

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
        setRecommendedBooks(data.filter(b => b.id !== parseInt(id) && b.id !== id).slice(0, 6));
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

  if (loading) return <div className="min-h-screen pt-32 text-center text-zinc-500 dark:text-zinc-400 bg-[#FDFBF7] dark:bg-[#121212]">{t('Loading Book…')}</div>;
  if (!book) return <div className="min-h-screen pt-32 text-center text-zinc-500 dark:text-zinc-400 bg-[#FDFBF7] dark:bg-[#121212]">{t('Book not found.')}</div>;

  const primaryAction = book.userHasRental ? (
    <button onClick={() => navigate(`/read/${book.id}`)}
      className="flex-1 py-4 bg-[#20d9c0] dark:bg-teal-600 hover:bg-[#17b8a6] dark:hover:bg-teal-500 text-white font-bold rounded-full shadow-lg shadow-teal-400/30 transition-all text-[15px]">
      {t('Read Now')}
    </button>
  ) : book.queueInfo?.effectiveAvailable ? (
    <button onClick={handleRent} disabled={actionLoading}
      className="flex-1 py-4 bg-[#20d9c0] dark:bg-teal-600 hover:bg-[#17b8a6] dark:hover:bg-teal-500 text-white font-bold rounded-full shadow-lg shadow-teal-400/30 transition-all text-[15px]">
      {actionLoading ? t('Please wait…') : t('Rent (Reserved)')}
    </button>
  ) : book.queueInfo?.userInQueue ? (
    <button disabled
      className="flex-1 py-4 bg-zinc-200 dark:bg-zinc-800 text-zinc-500 dark:text-zinc-400 font-bold rounded-full text-[15px]">
      #{book.queueInfo?.userPosition} {t('in Queue')}
    </button>
  ) : book.available_copies > 0 ? (
    <button onClick={handleRent} disabled={actionLoading}
      className="flex-1 py-4 bg-[#20d9c0] dark:bg-teal-600 hover:bg-[#17b8a6] dark:hover:bg-teal-500 text-white font-bold rounded-full shadow-lg shadow-teal-400/30 transition-all text-[15px]">
      {actionLoading ? t('Please wait…') : t('Borrow Book')}
    </button>
  ) : (
    <button onClick={handleQueue} disabled={actionLoading}
      className="flex-1 py-4 bg-amber-400 dark:bg-amber-500 hover:bg-amber-500 dark:hover:bg-amber-600 text-white font-bold rounded-full shadow-lg shadow-amber-400/30 transition-all text-[15px]">
      {actionLoading ? t('Please wait…') : t('Join Queue')}
    </button>
  );

  return (
    /* Outer container */
    <div className="min-h-screen bg-[#FDFBF7] dark:bg-[#121212] transition-colors">

      {/* Gradient hero band spanning full width but containing the grid */}
      <div className="w-full bg-gradient-to-b from-[#e8f0fe] via-[#f0eafd] to-[#FDFBF7] dark:from-[#2e1d52] dark:via-[#1e1e2f] dark:to-[#121212] pt-24 md:pt-32 pb-12 md:pb-20 transition-colors">
        <div className="max-w-5xl mx-auto px-6">

          {/* Top bar */}
          <div className="flex justify-between items-center mb-10 md:mb-16">
            <button onClick={() => navigate(-1)}
              className="w-10 h-10 flex items-center justify-center bg-white/80 dark:bg-zinc-800/80 hover:bg-white dark:hover:bg-zinc-700 backdrop-blur-sm rounded-full shadow-sm border border-zinc-200 dark:border-zinc-700 text-zinc-600 dark:text-zinc-300 transition-all">
              <ChevronLeft size={20} />
            </button>
            <span className="text-xs font-bold tracking-[0.2em] text-zinc-500 dark:text-zinc-400 uppercase">{t('Book Details')}</span>
            <button onClick={() => navigate('/search')}
              className="w-10 h-10 flex items-center justify-center bg-white/80 dark:bg-zinc-800/80 hover:bg-white dark:hover:bg-zinc-700 backdrop-blur-sm rounded-full shadow-sm border border-zinc-200 dark:border-zinc-700 text-zinc-600 dark:text-zinc-300 transition-all">
              <Search size={18} />
            </button>
          </div>

          {/* Main 2-Column Grid */}
          <div className="grid grid-cols-1 md:grid-cols-[280px_1fr] lg:grid-cols-[320px_1fr] gap-10 md:gap-16 items-start">
            
            {/* Left Column: Cover */}
            <div className="flex justify-center md:justify-start md:sticky md:top-32">
              <div className="relative w-[190px] sm:w-[220px] md:w-full aspect-[2/3] rounded-2xl overflow-hidden shadow-2xl border border-white/60 dark:border-zinc-700">
                <img src={book.cover_image || PH} onError={onErr} alt={book.title} className="w-full h-full object-cover" />
                {isDownloaded && (
                  <div className="absolute top-3 left-3 bg-[#53389e] text-white p-1.5 rounded-lg shadow-md">
                    <Bookmark size={14} fill="currentColor" />
                  </div>
                )}
              </div>
            </div>

            {/* Right Column: Details & Synopsis */}
            <div className="flex flex-col text-center md:text-left">
              <h1 className="text-2xl sm:text-3xl lg:text-4xl font-serif font-bold text-zinc-900 dark:text-zinc-100 mb-3 leading-snug md:leading-tight">{book.title}</h1>
              
              <p className="text-zinc-500 dark:text-zinc-400 text-[15px] md:text-lg mb-3">
                {book.author}
                {book.file_type && <span className="text-zinc-400 dark:text-zinc-600"> ({book.file_type.toUpperCase()})</span>}
              </p>
              
              {(book.category) && (
                <p className="text-xs font-bold tracking-[0.15em] text-[#d8a892] dark:text-[#fcd34d] uppercase mb-5">{book.category}</p>
              )}

              {/* Stars */}
              <div className="flex items-center justify-center md:justify-start gap-2 mb-4">
                {[1,2,3,4].map(i => <Star key={i} size={18} fill="#f59e0b" color="#f59e0b" />)}
                <Star size={18} fill="#d1d5db" color="#d1d5db" className="dark:fill-zinc-700 dark:text-zinc-700" />
                <span className="text-sm font-bold text-zinc-700 dark:text-zinc-300 ml-1">4.8</span>
              </div>

              {/* Available copies badge */}
              <div className="flex justify-center md:justify-start mb-8">
                <div className="inline-flex items-center gap-1.5 bg-white/80 dark:bg-zinc-800/80 border border-zinc-200 dark:border-zinc-700 px-3 py-1.5 rounded-full text-xs font-bold text-zinc-600 dark:text-zinc-300 shadow-sm">
                  <div className={`w-2 h-2 rounded-full ${book.available_copies > 0 ? 'bg-green-400' : 'bg-orange-400'}`} />
                  {book.available_copies > 0 ? `${book.available_copies} ${t('copies available')}` : t('All copies borrowed — join queue')}
                </div>
              </div>

              {/* Action row */}
              <div className="flex items-center justify-center md:justify-start gap-4 mb-10 w-full md:max-w-md">
                {/* Placeholder reader avatars */}
                <div className="flex items-center flex-shrink-0 hidden sm:flex">
                  {[0, 1, 2].map(i => (
                    <img key={i} src={`https://i.pravatar.cc/100?img=${i + 12}`} alt="Reader avatar" className="w-9 h-9 rounded-full border-2 border-white dark:border-zinc-900 object-cover -ml-2 first:ml-0 shadow-sm bg-zinc-100 dark:bg-zinc-800" />
                  ))}
                  <span className="ml-2 text-xs font-bold text-zinc-500 dark:text-zinc-400">+{book.total_copies || 0}</span>
                </div>

                {/* Primary action */}
                <div className="flex-1 flex min-w-0">
                  {primaryAction}
                </div>

                {/* Bookmark / download */}
                <button
                  onClick={book.userHasRental && !isDownloaded ? handleDownload : undefined}
                  disabled={isDownloading}
                  className={`w-12 h-12 flex-shrink-0 flex items-center justify-center rounded-full border-2 transition-all ${
                    isDownloaded
                      ? 'bg-[#53389e] border-[#53389e] text-white'
                      : 'bg-white dark:bg-zinc-800 border-zinc-200 dark:border-zinc-700 text-zinc-400 dark:text-zinc-500 hover:border-[#53389e] dark:hover:border-[#a78bfa] hover:text-[#53389e] dark:hover:text-[#a78bfa]'
                  }`}
                >
                  {isDownloading
                    ? <span className="animate-spin text-sm">◌</span>
                    : <Bookmark size={18} fill={isDownloaded ? 'currentColor' : 'none'} />
                  }
                </button>
              </div>

              {/* Synopsis Section */}
              <div className="bg-white dark:bg-[#1e1e1e] rounded-3xl shadow-lg border border-zinc-100 dark:border-zinc-800 p-6 md:p-8 text-left transition-colors">
                <h3 className="text-lg font-serif font-bold text-zinc-900 dark:text-zinc-100 mb-4">{t('Synopsis')}</h3>
                <div className="text-zinc-500 dark:text-zinc-400 leading-relaxed space-y-4 text-[15px]">
                  {book.description
                    ? book.description.split('\n').filter(p => p.trim()).map((para, i) => <p key={i}>{para}</p>)
                    : <p>{t('No synopsis available for this book yet. Dive in and start reading!')}</p>
                  }
                </div>
              </div>
            </div>

          </div>
        </div>
      </div>

      {/* Recommended Books Section at the bottom */}
      <div className="max-w-5xl mx-auto px-6 pb-20">
        {recommendedBooks.length > 0 && (
          <div className="mt-8">
            <div className="flex justify-between items-end mb-6">
              <h2 className="text-xl md:text-2xl font-serif font-bold text-zinc-900 dark:text-zinc-100">{t('You Might Also Like')}</h2>
              <Link to="/search" className="flex items-center gap-1.5 text-sm font-bold text-[#53389e] dark:text-[#a78bfa] hover:underline">
                {t('View all')} <ArrowRight size={14} />
              </Link>
            </div>
            <div className="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 lg:grid-cols-6 gap-4 sm:gap-5">
              {recommendedBooks.map(rec => (
                <Link to={`/book/${rec.id}`} key={rec.id} className="group">
                  <div className="aspect-[2/3] rounded-xl overflow-hidden shadow-md border border-zinc-100 dark:border-zinc-800 mb-3 bg-zinc-100 dark:bg-zinc-800 relative transition-colors">
                    <img src={rec.cover_image || PH} onError={onErr} alt={rec.title} className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500" />
                    <div className="absolute inset-x-0 bottom-0 p-2.5 bg-gradient-to-t from-black/60 to-transparent opacity-0 group-hover:opacity-100 transition-opacity">
                      <div className="w-full py-1.5 bg-[#20d9c0] dark:bg-teal-600 text-white text-[9px] uppercase tracking-wider font-bold rounded-lg flex items-center justify-center">
                        {t('Borrow')}
                      </div>
                    </div>
                  </div>
                  <h4 className="text-xs md:text-sm font-bold text-zinc-800 dark:text-zinc-200 truncate leading-snug" title={rec.title}>{rec.title}</h4>
                  <p className="text-[10px] md:text-xs text-zinc-400 dark:text-zinc-500 uppercase tracking-wider truncate mt-0.5">{rec.author}</p>
                </Link>
              ))}
            </div>
          </div>
        )}
      </div>

    </div>
  );
}
