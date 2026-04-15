import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { getDownloadedBooks } from '../utils/storage';
import api from '../api';

export default function LibraryPage() {
  const [tab, setTab] = useState('downloaded');
  
  const [downloaded, setDownloaded] = useState([]);
  const [rentals, setRentals] = useState([]);
  const [queue, setQueue] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchLibraryData() {
      try {
        setLoading(true);
        // Load downloaded offline books
        const offline = await getDownloadedBooks();
        setDownloaded(offline);

        // Fetch Rentals & Queue concurrently
        const [rentalsRes, queueRes] = await Promise.all([
          api.get('/user/rentals').catch(() => ({ data: [] })),
          api.get('/user/queue').catch(() => ({ data: [] }))
        ]);
        
        setRentals(rentalsRes.data || []);
        setQueue(queueRes.data || []);
      } catch (err) {
        console.error("Failed to load library data", err);
      } finally {
        setLoading(false);
      }
    }
    fetchLibraryData();
  }, []);

  const getDisplayBooks = () => {
    switch (tab) {
      case 'wishlist': return queue.map(q => ({ ...q, status: q.status === 'available' ? 'Available' : 'Waiting', cover: q.cover_image }));
      case 'history': return rentals.map(r => ({ ...r, status: 'Active Rental', cover: r.cover_image }));
      default: return downloaded.map(d => ({ ...d, status: 'Offline Ready', cover: d.cover_image }));
    }
  };

  const displayBooks = getDisplayBooks();

  return (
    <div className="pt-12 pb-24 px-6 relative">
      <h1 className="text-3xl font-serif font-bold text-zinc-900 mb-6">
        My Library
      </h1>

      <div className="flex gap-6 border-b border-zinc-200 mb-6">
        {['downloaded', 'wishlist', 'history'].map(t => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={`pb-2 text-sm font-medium capitalize transition-colors relative ${
              tab === t ? 'text-primary' : 'text-zinc-500 hover:text-zinc-700'
            }`}
          >
            {t}
            {tab === t && (
              <span className="absolute bottom-0 left-0 right-0 h-0.5 bg-primary rounded-t-full"></span>
            )}
          </button>
        ))}
      </div>

      <div className="grid grid-cols-2 gap-x-4 gap-y-8">
        {loading ? (
          <div className="col-span-2 text-center text-zinc-500 py-12">Loading...</div>
        ) : displayBooks.length === 0 ? (
          <div className="col-span-2 text-center text-zinc-500 py-12">
            No books found in {tab}.
          </div>
        ) : (
          displayBooks.map(book => {
            const actualBookId = book.book_id || book.id; 
            return (
              <Link to={`/book/${actualBookId}`} key={book.id || actualBookId} className="block group">
                <div className="aspect-[3/4] rounded-xl overflow-hidden shadow-md mb-3 bg-zinc-100">
                  {book.cover && <img src={book.cover} alt={book.title} className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500" />}
                </div>
                <h4 className="text-sm font-bold text-zinc-900 truncate">{book.title}</h4>
                <p className="text-[10px] text-zinc-500 uppercase tracking-wider truncate mb-2">{book.author}</p>
                
                <div className="w-full bg-zinc-200 h-0.5 rounded-full mb-1">
                  <div className="bg-zinc-900 h-0.5 rounded-full" style={{ width: '45%' }}></div>
                </div>
                <p className="text-[10px] text-zinc-400 font-medium">{book.status}</p>
              </Link>
            );
          })
        )}
      </div>
    </div>
  );
}
