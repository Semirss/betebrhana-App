import { useState } from 'react';
import { Search as SearchIcon } from 'lucide-react';

export default function SearchPage() {
  const [query, setQuery] = useState('');

  const TOP_CATEGORIES = ['Art & Design', 'Adventure', 'Horror', 'History', 'Science Fiction'];
  const TRENDING = [
    'Wes Anderson Books',
    'Classic Literature',
    'Science Fiction Top 10',
    'Art and Design Collections'
  ];

  return (
    <div className="min-h-screen pt-12 pb-24 px-6 bg-[var(--color-background-light)] dark:bg-[var(--color-background-dark)]">
      <h1 className="text-3xl font-serif font-bold text-zinc-900 dark:text-white mb-6">
        Search
      </h1>

      <div className="relative mb-8">
        <div className="absolute inset-y-0 left-4 flex items-center pointer-events-none">
          <SearchIcon size={18} className="text-zinc-400" />
        </div>
        <input 
          type="text" 
          placeholder="Titles, authors, or topics..." 
          value={query}
          onChange={e => setQuery(e.target.value)}
          className="w-full bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 rounded-2xl py-4 pl-12 pr-4 text-sm focus:outline-none focus:ring-2 focus:ring-primary shadow-sm transition-all"
        />
      </div>

      {!query && (
        <>
          <div className="mb-8">
            <h3 className="text-xs font-bold tracking-[0.1em] text-[#d8a892] uppercase mb-4">Top Categories</h3>
            <div className="flex flex-wrap gap-3">
              {TOP_CATEGORIES.map(cat => (
                <button key={cat} className="px-4 py-2 bg-blue-50/50 dark:bg-blue-900/10 text-blue-900 dark:text-blue-100 text-xs font-medium rounded-xl hover:bg-blue-100 dark:hover:bg-blue-900/30 transition-colors">
                  {cat}
                </button>
              ))}
            </div>
          </div>

          <div>
            <h3 className="text-xs font-bold tracking-[0.1em] text-[#d8a892] uppercase mb-4">Trending Searches</h3>
            <ul className="space-y-4">
              {TRENDING.map(search => (
                <li key={search} className="flex items-center gap-3 text-sm text-zinc-600 dark:text-zinc-400 cursor-pointer hover:text-primary transition-colors">
                  <SearchIcon size={16} className="text-zinc-300 dark:text-zinc-600" />
                  {search}
                </li>
              ))}
            </ul>
          </div>
        </>
      )}

      {query && (
        <div className="text-center text-zinc-500 mt-12 text-sm">
          Press enter to search for "{query}"
        </div>
      )}
    </div>
  );
}
