import { useState, useEffect } from 'react';
import { Search as SearchIcon, ArrowRight, Star } from 'lucide-react';
import { Link } from 'react-router-dom';
import api from '../api';
import { useLanguage } from '../context/LanguageContext';

const PH = 'https://placehold.co/300x450/e8e8e8/aaaaaa?text=No+Cover';
const onErr = (e) => { e.target.onerror = null; e.target.src = PH; };

export default function SearchPage() {
  const [query, setQuery] = useState('');
  const [books, setBooks] = useState([]);
  const [loading, setLoading] = useState(true);
  const { t } = useLanguage();

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

  // Extract real metadata for suggestions
  const uniqueAuthors = [...new Set(books.map(b => b.author).filter(Boolean))].slice(0, 5);
  const realTrendingTitles = books.map(b => b.title).filter(Boolean).slice(0, 4);

  const TOP_CATEGORIES = uniqueAuthors.length > 0 ? uniqueAuthors : ['Fiction', 'History', 'Science', 'Art'];
  const TRENDING = realTrendingTitles.length > 0 ? realTrendingTitles : ['The Great Gatsby', '1984', 'To Kill a Mockingbird'];

  const filteredBooks = query 
    ? books.filter(book => 
        book.title?.toLowerCase().includes(query.toLowerCase()) || 
        book.author?.toLowerCase().includes(query.toLowerCase()) ||
        book.category?.toLowerCase().includes(query.toLowerCase())
      )
    : books;

  return (
    <div className="min-h-screen pt-4 md:pt-32 pb-24 px-6 md:px-8 bg-[#FDFBF7] dark:bg-[#121212] transition-colors">
      <div className="max-w-[1200px] mx-auto">
        <h1 className="text-[2.5rem] font-serif font-bold text-zinc-900 dark:text-zinc-100 mb-8">
          {t('Search')}
        </h1>

        <div className="relative mb-12">
          <div className="absolute inset-y-0 left-5 flex items-center pointer-events-none">
            <SearchIcon size={20} className="text-zinc-400 dark:text-zinc-500" />
          </div>
          <input 
            type="text" 
            placeholder={t('Titles, authors, or topics...')} 
            value={query}
            onChange={e => setQuery(e.target.value)}
            className="w-full bg-white dark:bg-[#1e1e1e] border border-zinc-200 dark:border-zinc-800 rounded-full py-5 pl-14 pr-6 text-[15px] font-medium text-zinc-800 dark:text-zinc-200 focus:outline-none focus:border-[#53389e] dark:focus:border-[#a78bfa] focus:ring-4 focus:ring-[#53389e]/10 shadow-lg shadow-zinc-200/50 dark:shadow-none transition-all placeholder:text-zinc-400 dark:placeholder:text-zinc-500"
          />
        </div>

        {!query && (
          <div className="flex flex-col md:flex-row gap-16 mb-16">
            <div className="flex-1">
              <h3 className="text-xs font-bold tracking-[0.1em] text-[#d8a892] dark:text-[#fcd34d] uppercase mb-6">{t('Popular Authors')}</h3>
              <div className="flex flex-wrap gap-3">
                {TOP_CATEGORIES.map(cat => (
                  <button key={cat} onClick={() => setQuery(cat)} className="px-5 py-2.5 bg-blue-50 dark:bg-blue-900/30 hover:bg-blue-100 dark:hover:bg-blue-900/50 text-blue-900 dark:text-blue-300 text-xs font-bold rounded-xl transition-colors shadow-sm">
                    {cat}
                  </button>
                ))}
              </div>
            </div>

            <div className="flex-1">
              <h3 className="text-xs font-bold tracking-[0.1em] text-[#d8a892] dark:text-[#fcd34d] uppercase mb-6">{t('Trending Books')}</h3>
              <ul className="space-y-4">
                {TRENDING.map(search => (
                  <li key={search} onClick={() => setQuery(search)} className="flex items-center gap-3 text-sm font-medium text-zinc-500 dark:text-zinc-400 cursor-pointer hover:text-[#53389e] dark:hover:text-[#a78bfa] transition-colors">
                    <SearchIcon size={16} className="text-zinc-300 dark:text-zinc-600" />
                    {search}
                  </li>
                ))}
              </ul>
            </div>
          </div>
        )}

        {/* ALWAYS SHOW THE GRID */}
        <div>
          <div className="mb-8 flex justify-between items-end border-b border-zinc-100 dark:border-zinc-800 pb-4">
            <h2 className="text-xl font-bold text-zinc-900 dark:text-zinc-100">
              {query ? (
                <>{t('Results for')} <span className="text-[#53389e] dark:text-[#a78bfa]">"{query}"</span></>
              ) : (
                t('Explore Complete Library')
              )}
            </h2>
            <span className="text-sm font-medium text-zinc-500 dark:text-zinc-400">{filteredBooks.length} {t('titles available')}</span>
          </div>

          {loading ? (
            <div className="text-zinc-400 dark:text-zinc-500 py-12 text-center">{t('Loading library...')}</div>
          ) : filteredBooks.length > 0 ? (
            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-x-6 gap-y-10">
              {filteredBooks.map(book => (
                <div key={book.id} className="group">
                  <div className="aspect-[3/4] rounded-2xl overflow-hidden shadow-lg border border-zinc-100 dark:border-zinc-800 mb-4 relative bg-white dark:bg-[#1e1e1e] transition-colors">
                    <img src={book.cover_image || PH} onError={onErr} alt={book.title} className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105" />
                    <div className="absolute inset-x-0 bottom-0 p-4 bg-gradient-to-t from-black/60 to-transparent opacity-0 group-hover:opacity-100 transition-opacity flex justify-center">
                      <Link to={`/book/${book.id}`} className="w-full py-2 bg-[#53389e] hover:bg-[#432c81] text-white text-xs font-bold rounded-xl shadow-lg transform translate-y-4 group-hover:translate-y-0 transition-all flex items-center justify-center">
                        {t('Details')}
                      </Link>
                    </div>
                  </div>
                  
                  <h4 className="text-sm font-bold text-zinc-900 dark:text-zinc-100 mb-1 truncate" title={book.title}>{book.title}</h4>
                  <div className="flex items-center justify-between">
                    <p className="text-[10px] text-zinc-500 dark:text-zinc-400 uppercase tracking-widest truncate max-w-[70%]">{book.author}</p>
                    <div className="flex items-center gap-1 text-[10px] font-bold text-zinc-600 dark:text-zinc-400">
                      <Star fill="#53389e" color="#53389e" size={10} /> 4.8
                    </div>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="text-zinc-500 dark:text-zinc-400 py-24 text-center">
              {t('No books matched your search.')}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
