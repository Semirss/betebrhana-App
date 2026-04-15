import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { Search, Star, TrendingUp, BookOpen, ChevronRight } from 'lucide-react';
import api from '../api';

const CATEGORIES = [
  { label: 'All',          color: '#EC7D22', bg: '#fff7ed' },
  { label: 'Fiction',      color: '#6366f1', bg: '#eef2ff' },
  { label: 'History',      color: '#0ea5e9', bg: '#e0f2fe' },
  { label: 'Science',      color: '#10b981', bg: '#d1fae5' },
  { label: 'Art & Design', color: '#f43f5e', bg: '#ffe4e6' },
  { label: 'Adventure',    color: '#f59e0b', bg: '#fef3c7' },
  { label: 'Philosophy',   color: '#8b5cf6', bg: '#ede9fe' },
  { label: 'Biography',    color: '#14b8a6', bg: '#ccfbf1' },
  { label: 'Religion',     color: '#ec4899', bg: '#fce7f3' },
  { label: 'Children',     color: '#84cc16', bg: '#f7fee7' },
];

export default function HomePage() {
  const [books, setBooks]           = useState([]);
  const [loading, setLoading]       = useState(true);
  const [activeCategory, setActiveCategory] = useState('All');

  useEffect(() => {
    async function fetchData() {
      try {
        const res = await api.get('/books');
        setBooks(res.data || []);
      } catch (err) {
        console.error('Failed to fetch books', err);
      } finally {
        setLoading(false);
      }
    }
    fetchData();
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full text-zinc-400 text-sm">
        Loading books…
      </div>
    );
  }

  // Data slices
  const featuredMobile  = books[0];
  const mobileArrivals  = books.slice(1);
  const featured6       = books.slice(0, 6);
  const newArrivals     = books.slice(6, 22);

  return (
    <>
      {/* ══════════════════════════════════════
          MOBILE LAYOUT  (hidden on ≥768px)
      ══════════════════════════════════════ */}
      <div className="mobile-discover pt-12 pb-6 px-6">
        <div className="flex justify-between items-center mb-8">
          <div>
            <h2 className="text-xs font-semibold text-primary uppercase tracking-widest mb-1">Discover</h2>
            <h1 className="text-3xl font-serif font-bold text-zinc-900">Library</h1>
          </div>
          <Link to="/search" className="p-2 rounded-full border border-zinc-200 bg-white/50 backdrop-blur-sm">
            <Search size={20} className="text-zinc-600" />
          </Link>
        </div>

        {featuredMobile && (
          <div className="flex flex-col items-center mb-12">
            <p className="text-[10px] text-zinc-500 font-bold uppercase tracking-widest mb-2">Popular books of</p>
            <h3 className="text-2xl font-serif font-bold text-zinc-900 mb-6">
              {featuredMobile.category || 'Featured'}
            </h3>
            <div className="relative w-full max-w-xs aspect-[3/4] rounded-2xl overflow-hidden shadow-2xl mb-6 bg-zinc-100 hover:scale-105 transition-transform duration-500">
              {featuredMobile.cover_image && (
                <img src={featuredMobile.cover_image} alt="Cover" className="w-full h-full object-cover" />
              )}
            </div>
            <h4 className="text-xl text-center font-serif font-bold text-zinc-900 mb-1">{featuredMobile.title}</h4>
            <p className="text-sm text-center text-zinc-500 mb-4">{featuredMobile.author}</p>
            <div className="flex items-center gap-4 text-xs text-zinc-400 mb-6 font-medium">
              <span>{featuredMobile.total_copies} Copies</span>
              <span className="flex items-center text-primary"><span className="text-yellow-400 mr-1">★</span>4.8</span>
            </div>
            <Link
              to={`/book/${featuredMobile.id}`}
              className="px-8 py-3 rounded-full bg-zinc-900 text-white font-semibold text-sm hover:shadow-lg transition-shadow"
            >
              Open Now
            </Link>
          </div>
        )}

        <div className="mb-6">
          <div className="flex justify-between items-center mb-4">
            <h3 className="font-serif font-bold text-lg text-zinc-900">New Arrivals</h3>
            <span className="text-xs text-zinc-400 font-medium">{mobileArrivals.length}</span>
          </div>
          <div className="flex gap-4 overflow-x-auto pb-4 snap-x no-scrollbar">
            {mobileArrivals.map(book => (
              <Link to={`/book/${book.id}`} key={book.id} className="block w-32 flex-shrink-0 snap-start">
                <div className="aspect-[3/4] rounded-xl overflow-hidden shadow-md mb-3 bg-zinc-100">
                  {book.cover_image && (
                    <img src={book.cover_image} alt={book.title} className="w-full h-full object-cover" />
                  )}
                </div>
                <h4 className="text-sm font-bold text-zinc-900 truncate">{book.title}</h4>
                <p className="text-[10px] text-zinc-500 uppercase tracking-wider truncate">{book.author}</p>
              </Link>
            ))}
          </div>
        </div>
      </div>

      {/* ══════════════════════════════════════
          DESKTOP LAYOUT  (hidden on <768px)
          Categories | Featured | New Arrivals
      ══════════════════════════════════════ */}
      <div className="desktop-discover">
        <div className="desktop-discover-grid">

          {/* ── Left: Categories ── */}
          <aside className="discover-panel-left">
            <h2 className="discover-panel-title">
              <BookOpen size={13} /> Browse
            </h2>
            <div className="cat-list">
              {CATEGORIES.map(cat => (
                <button
                  key={cat.label}
                  onClick={() => setActiveCategory(cat.label)}
                  className="cat-pill"
                  style={
                    activeCategory === cat.label
                      ? { background: cat.bg, color: cat.color, borderColor: cat.color }
                      : {}
                  }
                >
                  <span
                    className="cat-dot"
                    style={{ background: cat.color }}
                  />
                  {cat.label}
                  {activeCategory === cat.label && (
                    <ChevronRight size={12} style={{ marginLeft: 'auto', color: cat.color }} />
                  )}
                </button>
              ))}
            </div>
          </aside>

          {/* ── Center: Featured compact grid ── */}
          <section className="discover-panel-center">
            {/* Header */}
            <div className="discover-panel-header">
              <div>
                <p className="discover-section-eyebrow">Popular Books</p>
                <h1 className="discover-section-title">Featured</h1>
              </div>
              <Link to="/search" className="discover-search-btn">
                <Search size={17} />
              </Link>
            </div>

            {/* 6 compact horizontal cards in 2-col × 3-row grid */}
            <div className="featured-books-grid">
              {featured6.map((book, i) => (
                <Link to={`/book/${book.id}`} key={book.id} className="feat-card">
                  <div className="feat-card-cover">
                    {book.cover_image
                      ? <img src={book.cover_image} alt={book.title} />
                      : <div className="feat-card-cover-placeholder" />
                    }
                  </div>
                  <div className="feat-card-body">
                    <h3 className="feat-card-title">{book.title}</h3>
                    <p className="feat-card-author">{book.author}</p>
                    <div className="feat-card-rating">
                      <Star size={10} fill="#EC7D22" color="#EC7D22" />
                      <span>4.8</span>
                      {book.category && <span className="feat-card-cat">{book.category}</span>}
                    </div>
                  </div>
                  <ChevronRight size={14} className="feat-card-arrow" />
                </Link>
              ))}
            </div>

            {/* Quick category row below */}
            <div className="center-cat-strip">
              {CATEGORIES.slice(1, 6).map(cat => (
                <button
                  key={cat.label}
                  onClick={() => setActiveCategory(cat.label)}
                  className="center-cat-chip"
                  style={{ background: cat.bg, color: cat.color }}
                >
                  {cat.label}
                </button>
              ))}
            </div>
          </section>

          {/* ── Right: New Arrivals ── */}
          <aside className="discover-panel-right">
            <h2 className="discover-panel-title">
              <TrendingUp size={13} /> New Arrivals
            </h2>
            <div className="new-arrivals-list">
              {newArrivals.map((book, i) => (
                <Link to={`/book/${book.id}`} key={book.id} className="new-arrival-item">
                  <span className="new-arrival-rank">{String(i + 1).padStart(2, '0')}</span>
                  <div className="new-arrival-cover">
                    {book.cover_image && <img src={book.cover_image} alt={book.title} />}
                  </div>
                  <div className="new-arrival-info">
                    <h4>{book.title}</h4>
                    <p>{book.author}</p>
                  </div>
                </Link>
              ))}
            </div>
          </aside>

        </div>
      </div>
    </>
  );
}
