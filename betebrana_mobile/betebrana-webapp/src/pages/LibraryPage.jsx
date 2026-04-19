import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { getDownloadedBooks } from '../utils/storage';
import api from '../api';
import { useLanguage } from '../context/LanguageContext';

const PH = 'https://placehold.co/300x450/ede9fe/53389e?text=No+Cover';
const onErr = (e) => { e.target.onerror = null; e.target.src = PH; };

export default function LibraryPage() {
  const [tab, setTab] = useState('rentals');
  const [allBooks, setAllBooks] = useState([]);   // full book objects with cover_image
  const [rentals, setRentals] = useState([]);
  const [queue, setQueue] = useState([]);
  const [downloaded, setDownloaded] = useState([]);
  const [loading, setLoading] = useState(true);
  const { t } = useLanguage();

  const TABS = [
    { key: 'rentals',    label: t('My Rentals')  },
    { key: 'wishlist',   label: t('Wishlist')     },
    { key: 'downloaded', label: t('Downloaded')   },
  ];

  useEffect(() => {
    async function fetchData() {
      try {
        setLoading(true);

        // Fetch everything in parallel
        const [booksRes, rentalsRes, queueRes, offline] = await Promise.all([
          api.get('/books').catch(() => ({ data: [] })),
          api.get('/user/rentals').catch(() => ({ data: [] })),
          api.get('/user/queue').catch(() => ({ data: [] })),
          getDownloadedBooks().catch(() => []),
        ]);

        setAllBooks(booksRes.data || []);
        setRentals(rentalsRes.data || []);
        setQueue(queueRes.data || []);
        setDownloaded(offline || []);
      } catch (err) {
        console.error('Failed to load library data', err);
      } finally {
        setLoading(false);
      }
    }
    fetchData();
  }, []);

  // Helper: given a book_id, find the full book object (with cover_image) from the all-books list
  const enrichBook = (record, statusLabel) => {
    const bookId = record.book_id || record.id;
    const fullBook = allBooks.find(b => b.id === bookId || b.id === parseInt(bookId)) || {};
    return {
      id: record.id,
      book_id: bookId,
      title: record.title || fullBook.title || 'Unknown Title',
      author: record.author || fullBook.author || '',
      cover: fullBook.cover_image || record.cover_image || null,
      status: statusLabel,
    };
  };

  const getDisplayBooks = () => {
    switch (tab) {
      case 'rentals':
        return rentals.map(r => enrichBook(r, 'Active Rental'));
      case 'wishlist':
        return queue.map(q => enrichBook(q, q.status === 'available' ? 'Ready to Borrow' : 'In Queue'));
      case 'downloaded':
        return downloaded.map(d => enrichBook(d, 'Offline Ready'));
      default:
        return [];
    }
  };

  const displayBooks = getDisplayBooks();

  return (
    <div className="pt-4 md:pt-32 pb-24 px-6 md:px-8 max-w-[1200px] mx-auto relative min-h-screen bg-[#FDFBF7] dark:bg-[#121212] transition-colors">
      <h1 className="text-3xl font-serif font-bold text-zinc-900 dark:text-zinc-100 mb-8">{t('My Library')}</h1>

      {/* Tabs */}
      <div className="flex gap-8 border-b border-zinc-200 dark:border-zinc-800 mb-10">
        {TABS.map(({ key, label }) => (
          <button
            key={key}
            onClick={() => setTab(key)}
            className={`pb-3 text-sm font-bold transition-colors relative ${
              tab === key ? 'text-[#53389e] dark:text-[#a78bfa]' : 'text-zinc-400 dark:text-zinc-500 hover:text-zinc-700 dark:hover:text-zinc-300'
            }`}
          >
            {label}
            {tab === key && (
              <span className="absolute bottom-0 left-0 right-0 h-0.5 bg-[#53389e] dark:bg-[#a78bfa] rounded-t-full" />
            )}
          </button>
        ))}
      </div>

      {/* Grid */}
      <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-x-6 gap-y-10">
        {loading ? (
          <div className="col-span-5 text-center text-zinc-400 dark:text-zinc-500 py-16">{t('Loading your library…')}</div>
        ) : displayBooks.length === 0 ? (
          <div className="col-span-5 text-center text-zinc-400 dark:text-zinc-500 py-16">
            {tab === 'rentals' && t('You have no active rentals right now.')}
            {tab === 'wishlist' && t('Your wishlist is empty.')}
            {tab === 'downloaded' && t('No books downloaded for offline reading.')}
          </div>
        ) : (
          displayBooks.map((book, idx) => (
            <Link
              to={`/book/${book.book_id}`}
              key={`${book.book_id}-${idx}`}
              className="block group"
            >
              <div className="aspect-[3/4] rounded-2xl overflow-hidden shadow-lg border border-zinc-100 dark:border-zinc-800 mb-4 bg-zinc-100 dark:bg-zinc-800 relative transition-colors">
                <img
                  src={book.cover || PH}
                  onError={onErr}
                  alt={book.title}
                  className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                />
                {/* Hover overlay */}
                <div className="absolute inset-x-0 bottom-0 p-3 bg-gradient-to-t from-black/50 to-transparent opacity-0 group-hover:opacity-100 transition-opacity flex justify-center">
                  <div className="w-full py-2 bg-[#53389e] text-white text-[10px] uppercase tracking-wider font-bold rounded-lg flex items-center justify-center">
                    {t('Open')}
                  </div>
                </div>
              </div>
              <h4 className="text-sm font-bold text-zinc-900 dark:text-zinc-100 truncate mb-0.5" title={book.title}>{book.title}</h4>
              <p className="text-[10px] text-zinc-500 dark:text-zinc-400 uppercase tracking-wider truncate mb-2">{book.author}</p>
              <span className={`inline-block text-[10px] font-bold px-2.5 py-1 rounded-full ${
                book.status === 'Active Rental'
                  ? 'bg-[#bbf7d0] dark:bg-emerald-900/30 text-[#166534] dark:text-emerald-400'
                  : book.status === 'Ready to Borrow'
                  ? 'bg-[#ede9fe] dark:bg-purple-900/30 text-[#53389e] dark:text-purple-400'
                  : 'bg-zinc-100 dark:bg-zinc-800 text-zinc-600 dark:text-zinc-400'
              }`}>
                {book.status}
              </span>
            </Link>
          ))
        )}
      </div>
    </div>
  );
}
