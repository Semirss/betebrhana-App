import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { Search } from 'lucide-react';
import api from '../api';

export default function HomePage() {
  const [books, setBooks] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchBooks() {
      try {
        const res = await api.get('/books');
        setBooks(res.data);
      } catch (err) {
        console.error("Failed to fetch books", err);
      } finally {
        setLoading(false);
      }
    }
    fetchBooks();
  }, []);

  if (loading) {
    return <div className="min-h-screen flex items-center justify-center">Loading books...</div>;
  }

  const featured = books.length > 0 ? books[0] : null;
  const newArrivals = books.slice(1);

  return (
    <div className="pt-12 pb-24 px-6 relative">
      {/* Header */}
      <div className="flex justify-between items-center mb-8">
        <div>
          <h2 className="text-xs font-semibold text-primary uppercase tracking-widest mb-1">Discover</h2>
          <h1 className="text-3xl font-serif font-bold text-zinc-900 relative">
            Library
          </h1>
        </div>
        <button className="p-2 rounded-full border border-zinc-200 bg-white/50 backdrop-blur-sm">
          <Search size={20} className="text-zinc-600" />
        </button>
      </div>

      {/* Featured Section */}
      {featured && (
        <div className="flex flex-col items-center mb-12">
          <p className="text-[10px] text-zinc-500 font-bold uppercase tracking-widest mb-2">Popular books of</p>
          <h3 className="text-2xl font-serif font-bold text-zinc-900 mb-6">{featured.category || 'Featured'}</h3>

          {/* Book Carousel Hero */}
          <div className="relative w-full max-w-xs aspect-[3/4] rounded-2xl overflow-hidden shadow-2xl mb-6 flex-shrink-0 z-10 transition-transform hover:scale-105 duration-500 bg-zinc-100">
            {featured.cover_image && <img src={featured.cover_image} alt="Cover" className="w-full h-full object-cover" />}
          </div>
          
          <h4 className="text-xl text-center font-serif font-bold text-zinc-900 mb-1">{featured.title}</h4>
          <p className="text-sm text-center text-zinc-500 mb-4">{featured.author}</p>
          
          <div className="flex items-center gap-4 text-xs text-zinc-400 mb-6 font-medium">
            <span>{featured.total_copies} Copies</span>
            <span className="flex items-center text-primary"><span className="text-yellow-400 mr-1">★</span> 4.8</span>
          </div>

          <Link to={`/book/${featured.id}`} className="px-8 py-3 rounded-full bg-zinc-900 text-white font-semibold text-sm hover:shadow-lg transition-shadow">
            Open Now
          </Link>
        </div>
      )}

      {/* New Arrivals list */}
      <div>
        <div className="flex justify-between items-center mb-4">
          <h3 className="font-serif font-bold text-lg text-zinc-900">New Arrivals</h3>
          <span className="text-xs text-zinc-400 font-medium">{newArrivals.length}</span>
        </div>
        <div className="flex gap-4 overflow-x-auto pb-4 snap-x no-scrollbar">
          {newArrivals.map(book => (
            <Link to={`/book/${book.id}`} key={book.id} className="block w-32 flex-shrink-0 snap-start">
              <div className="aspect-[3/4] rounded-xl overflow-hidden shadow-md mb-3 bg-zinc-100">
                {book.cover_image && <img src={book.cover_image} alt={book.title} className="w-full h-full object-cover" />}
              </div>
              <h4 className="text-sm font-bold text-zinc-900 truncate">{book.title}</h4>
              <p className="text-[10px] text-zinc-500 uppercase tracking-wider truncate mb-2">{book.author}</p>
            </Link>
          ))}
        </div>
      </div>
    </div>
  );
}
