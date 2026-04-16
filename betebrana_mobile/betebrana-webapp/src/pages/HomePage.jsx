import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { Search, Play, ArrowRight, Star } from 'lucide-react';
import api from '../api';

const PH = 'https://placehold.co/300x450/e8e8e8/aaaaaa?text=No+Cover';
const onErr = (e) => { e.target.onerror = null; e.target.src = PH; };

export default function HomePage() {
  const [books, setBooks] = useState([]);
  const [loading, setLoading] = useState(true);

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
    return <div className="flex items-center justify-center h-screen text-zinc-400 text-sm bg-[#FDFBF7]">Loading…</div>;
  }

  const popular = books.slice(0, 4);
  const featuredMobile = books[0];
  const mobileArrivals = books.slice(1, 10);

  return (
    <>
      {/* ── MOBILE (Unaffected) ── */}
      <div className="md:hidden mobile-discover pt-12 pb-6 px-4 bg-[#FDFBF7] min-h-screen">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
          <h1 style={{ fontSize: 22, fontWeight: 800, color: '#18181b', margin: 0 }}>Discover</h1>
          <Link to="/search" style={{ padding: 8, borderRadius: '50%', background: 'white', border: '1px solid #e4e4e7', display: 'flex' }}>
            <Search size={18} color="#52525b" />
          </Link>
        </div>
        
        {featuredMobile && (
          <div className="flex flex-col items-center mb-12">
            <h3 className="text-2xl font-serif font-bold text-zinc-900 mb-6">{featuredMobile.category || 'Featured'}</h3>
            <div className="relative w-full max-w-xs aspect-[3/4] rounded-2xl overflow-hidden shadow-2xl mb-6 bg-zinc-100">
              <img src={featuredMobile.cover_image || PH} onError={onErr} alt="Cover" className="w-full h-full object-cover" />
            </div>
            <h4 className="text-xl text-center font-serif font-bold text-zinc-900 mb-1">{featuredMobile.title}</h4>
            <p className="text-sm text-center text-zinc-500 mb-6">{featuredMobile.author}</p>
            <Link to={`/book/${featuredMobile.id}`} className="px-8 py-3 rounded-full bg-[#53389e] text-white font-semibold text-sm">
              Open Now
            </Link>
          </div>
        )}

        <div className="mb-6">
          <h3 className="font-serif font-bold text-lg text-zinc-900 mb-4">New Arrivals</h3>
          <div className="flex gap-4 overflow-x-auto pb-4 snap-x no-scrollbar">
            {mobileArrivals.map(book => (
              <Link to={`/book/${book.id}`} key={book.id} className="block w-32 flex-shrink-0 snap-start">
                <div className="aspect-[3/4] rounded-xl overflow-hidden shadow-md mb-3 bg-zinc-100">
                  <img src={book.cover_image || PH} onError={onErr} alt={book.title} className="w-full h-full object-cover" />
                </div>
                <h4 className="text-sm font-bold text-zinc-900 truncate">{book.title}</h4>
                <p className="text-[10px] text-zinc-500 uppercase tracking-wider truncate">{book.author}</p>
              </Link>
            ))}
          </div>
        </div>
      </div>

      {/* ── DESKTOP (Auca Style) ── */}
      <div className="hidden md:block pt-32 lg:pt-20 pb-0 bg-[#FDFBF7] min-h-screen">
        
        {/* HERO SECTION */}
        <section className="max-w-[1200px] mx-auto px-8 flex items-center justify-between gap-16 mb-40">
          
          {/* Left Text */}
          <div className="max-w-[500px]">
            <h1 className="text-[3.5rem] leading-[1.1] font-bold text-zinc-900 mb-6 font-serif">
              Find the perfect book for <span style={{ color: '#53389e', position: 'relative', display: 'inline-block' }}>
                every moment.
                <svg className="absolute w-full h-[8px] left-0 -bottom-1" viewBox="0 0 100 10" preserveAspectRatio="none">
                  <path d="M0,5 Q50,0 100,5" stroke="#bbf7d0" strokeWidth="4" fill="transparent" strokeLinecap="round" />
                </svg>
              </span>
            </h1>
            <p className="text-lg text-zinc-500 mb-10 leading-relaxed max-w-[400px]">
              Borrow books easily, explore curated collections, and enjoy reading anytime, anywhere.
            </p>
            <div className="flex items-center gap-4">
              <Link to="/library" className="px-8 py-4 bg-[#53389e] hover:bg-[#432c81] text-white rounded-xl font-bold transition-all shadow-lg shadow-purple-900/20">
                Borrow Now
              </Link>
              <Link to="/search" className="px-8 py-4 bg-white hover:bg-zinc-50 text-zinc-800 rounded-xl font-bold transition-all border border-zinc-200">
                Browse Collection
              </Link>
            </div>
          </div>

          {/* Right Image/Widgets */}
          <div className="relative flex-1 h-[550px] lg:h-[600px] mt-10 md:mt-0 flex items-center justify-center">
            
            {/* Soft background glow */}
            <div className="absolute w-[400px] h-[400px] bg-gradient-to-tr from-[#ede9fe] to-[#ecfdf5] rounded-full blur-3xl opacity-50 pointer-events-none"></div>
            
            {/* The Main Hero Visual */}
            <div className="relative z-10 w-[300px] lg:w-[340px] h-[400px] lg:h-[460px] bg-zinc-100 rounded-3xl overflow-hidden shadow-2xl border border-zinc-200" style={{ transform: 'rotate(2deg)' }}>
               {/* Replace with a woman reading/listening from reference */}
               <img src="https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?auto=format&fit=crop&q=80&w=600" alt="Reading" className="w-full h-full object-cover opacity-90" />
            </div>

            {/* Top Right Info Pills Group */}
            <div className="absolute top-10 -right-8 lg:-right-4 flex gap-4 z-30">
              <div className="bg-[#dcfce7] px-6 py-3 rounded-2xl shadow-lg border border-[#bbf7d0] text-center">
                <p className="text-xl font-bold text-[#166534] mb-0.5">21K+</p>
                <p className="text-[9px] text-[#166534] uppercase tracking-widest font-bold opacity-80">Titles</p>
              </div>
              <div className="bg-[#ede9fe] px-6 py-3 rounded-2xl shadow-lg border border-[#ddd6fe] text-center">
                <p className="text-xl font-bold text-[#53389e] mb-0.5">57K+</p>
                <p className="text-[9px] text-[#53389e] uppercase tracking-widest font-bold opacity-80">Readers</p>
              </div>
            </div>

            {/* Static Floating Book 1 (Top Left) */}
            <div className="absolute top-16 lg:top-24 left-0 lg:-left-6 w-[120px] lg:w-[140px] aspect-[2/3] rounded-xl overflow-hidden shadow-2xl border-4 border-white z-20" style={{ transform: 'rotate(-12deg)' }}>
              <img src="https://images.unsplash.com/photo-1544947950-fa07a98d237f?auto=format&fit=crop&q=80&w=300" className="w-full h-full object-cover" alt="Book Cover 1" />
            </div>

            {/* Static Floating Book 2 (Bottom Right) */}
            <div className="absolute bottom-12 lg:bottom-16 -right-6 w-[140px] lg:w-[160px] aspect-[2/3] rounded-xl overflow-hidden shadow-2xl border-4 border-white z-20" style={{ transform: 'rotate(8deg)' }}>
              <img src="https://images.unsplash.com/photo-1589829085413-56de8ae18c73?auto=format&fit=crop&q=80&w=300" className="w-full h-full object-cover" alt="Book Cover 2" />
            </div>

             {/* Small circular play button near Book 2 */}
             <div className="absolute bottom-40 -right-10 lg:-right-2 w-12 h-12 bg-[#bbf7d0] border-2 border-white rounded-full shadow-lg flex items-center justify-center z-30 hidden md:flex">
               <Play size={18} fill="#166534" className="text-[#166534] ml-1" />
             </div>

            {/* Audio/Progress Widget (Bottom Left) */}
            <div className="absolute bottom-20 -left-12 lg:-left-20 bg-white p-4 lg:p-5 rounded-2xl shadow-[0_8px_30px_rgb(0,0,0,0.12)] flex items-center gap-5 z-30 border border-zinc-100">
              <div className="w-12 h-12 rounded-full bg-[#53389e] flex items-center justify-center text-white shadow-md cursor-pointer hover:bg-[#432c81] transition-colors">
                <Play size={18} fill="white" className="ml-1" />
              </div>
              <div className="flex flex-col gap-2.5">
                <div className="text-[10px] font-bold text-zinc-400 uppercase tracking-wider">Chapter Eight</div>
                <div className="w-32 h-1.5 bg-zinc-100 rounded-full">
                  <div className="w-1/2 h-full bg-[#53389e] rounded-full relative">
                    <div className="absolute right-0 top-1/2 -translate-y-1/2 w-3 h-3 bg-white border-2 border-[#53389e] rounded-full shadow-sm"></div>
                  </div>
                </div>
                <div className="flex justify-between items-center px-1 mt-1">
                   <div className="w-3 h-3 rounded-full border border-zinc-300"></div>
                   <div className="w-3 h-3 rounded-full border border-[#53389e] bg-[#53389e]/10"></div>
                   <div className="w-3 h-3 rounded-full border border-zinc-300"></div>
                </div>
              </div>
            </div>

          </div>
        </section>

        {/* POPULAR BOOKS SECTION */}
        <section className="max-w-[1200px] mx-auto px-8 mb-32">
          <div className="flex justify-between items-end mb-10">
            <div>
              <p className="text-[#53389e] font-bold text-sm tracking-widest uppercase mb-2">Curated for you</p>
              <h2 className="text-3xl font-serif font-bold text-zinc-900 tracking-tight">Popular Books This Week</h2>
            </div>
            <Link to="/search" className="flex items-center gap-2 px-6 py-2.5 bg-[#bbf7d0] hover:bg-[#86efac] text-[#166534] rounded-full text-sm font-bold transition-colors">
              Explore More <ArrowRight size={16} />
            </Link>
          </div>

          <div className="grid grid-cols-4 gap-8">
            {popular.map(book => (
              <div key={book.id} className="group">
                <div className="aspect-[3/4] rounded-2xl overflow-hidden shadow-lg border border-zinc-100 mb-5 relative bg-white">
                  <img src={book.cover_image || PH} onError={onErr} alt={book.title} className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105" />
                  {/* Status Pill */}
                  <div className="absolute top-3 right-3 bg-white/90 backdrop-blur-sm px-3 py-1 rounded-full text-[10px] font-bold text-zinc-800 shadow-sm border border-black/5">
                    {book.total_copies > 0 ? "Available" : "Borrowed"}
                  </div>
                  {/* Hover Borrow Overlay */}
                  <div className="absolute inset-x-0 bottom-0 p-4 bg-gradient-to-t from-black/60 to-transparent opacity-0 group-hover:opacity-100 transition-opacity flex justify-center">
                    <Link to={`/book/${book.id}`} className="w-full py-2.5 bg-[#53389e] hover:bg-[#432c81] text-white text-xs font-bold rounded-xl shadow-lg transform translate-y-4 group-hover:translate-y-0 transition-all flex items-center justify-center">
                      View Details
                    </Link>
                  </div>
                </div>
                
                <h4 className="text-base font-bold text-zinc-900 mb-1 leading-snug truncate" title={book.title}>{book.title}</h4>
                
                <div className="flex items-center justify-between">
                  <p className="text-xs text-zinc-500 uppercase tracking-widest truncate max-w-[70%]">{book.author}</p>
                  <div className="flex items-center gap-1.5 text-xs font-bold text-zinc-600">
                    <Star fill="#53389e" color="#53389e" size={12} /> 4.8
                  </div>
                </div>
              </div>
            ))}
          </div>
        </section>

        {/* BROWSE CATEGORIES SECTION */}
        <section className="bg-zinc-50 py-24 border-t border-zinc-200/50">
          <div className="max-w-[1200px] mx-auto px-8">
            <div className="text-center mb-16">
              <h2 className="text-3xl font-serif font-bold text-zinc-900 mb-4">Browse by Category</h2>
              <p className="text-zinc-500">Dive into your favorite genres and discover new topics.</p>
            </div>
            
            <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-6">
              {[
                { name: "Fiction", color: "bg-blue-50 text-blue-700 hover:bg-blue-100 border-blue-100" },
                { name: "Science & Math", color: "bg-green-50 text-green-700 hover:bg-green-100 border-green-100" },
                { name: "History", color: "bg-amber-50 text-amber-700 hover:bg-amber-100 border-amber-100" },
                { name: "Art & Design", color: "bg-rose-50 text-rose-700 hover:bg-rose-100 border-rose-100" },
                { name: "Philosophy", color: "bg-purple-50 text-purple-700 hover:bg-purple-100 border-purple-100" }
              ].map((c) => (
                <Link to={`/search?category=${c.name}`} key={c.name} className={`h-32 flex items-center justify-center rounded-2xl border transition-all cursor-pointer shadow-sm hover:shadow-md ${c.color}`}>
                  <span className="font-bold text-lg">{c.name}</span>
                </Link>
              ))}
            </div>
          </div>
        </section>

        {/* FOOTER */}
        <footer className="bg-white border-t border-zinc-200/80 pt-16 pb-8">
          <div className="max-w-[1200px] mx-auto px-8 grid grid-cols-4 gap-12 mb-16">
            <div className="col-span-1">
              <div className="flex items-center gap-2 mb-6">
                <div className="w-8 h-8 rounded-lg bg-[#53389e] flex items-center justify-center text-white">
                  <Play size={18} />
                </div>
                <span className="font-bold text-xl text-zinc-900 tracking-tight">BeteBrana</span>
              </div>
              <p className="text-xs text-zinc-500 leading-relaxed max-w-[250px]">
                Providing accessible reading materials and curated collections for learners and enthusiasts.
              </p>
            </div>
            
            <div>
              <h4 className="font-bold text-zinc-900 text-sm mb-6">Platform</h4>
              <ul className="flex flex-col gap-4 text-xs font-medium text-zinc-500">
                <li><Link to="/search" className="hover:text-[#53389e] transition-colors">Browse Library</Link></li>
                <li><Link to="/search?filter=new" className="hover:text-[#53389e] transition-colors">New Arrivals</Link></li>
                <li><Link to="/search?filter=popular" className="hover:text-[#53389e] transition-colors">Trending Now</Link></li>
              </ul>
            </div>
            
            <div>
              <h4 className="font-bold text-zinc-900 text-sm mb-6">Support</h4>
              <ul className="flex flex-col gap-4 text-xs font-medium text-zinc-500">
                <li><Link to="/faq" className="hover:text-[#53389e] transition-colors">Help Center</Link></li>
                <li><Link to="/contact" className="hover:text-[#53389e] transition-colors">Contact Us</Link></li>
                <li><Link to="/status" className="hover:text-[#53389e] transition-colors">System Status</Link></li>
              </ul>
            </div>

            <div>
              <h4 className="font-bold text-zinc-900 text-sm mb-6">Legal</h4>
              <ul className="flex flex-col gap-4 text-xs font-medium text-zinc-500">
                <li><Link to="/terms" className="hover:text-[#53389e] transition-colors">Terms of Service</Link></li>
                <li><Link to="/privacy" className="hover:text-[#53389e] transition-colors">Privacy Policy</Link></li>
              </ul>
            </div>
          </div>
          
          <div className="max-w-[1200px] mx-auto px-8 pt-8 border-t border-zinc-100 flex justify-between items-center text-[11px] text-zinc-400 font-medium">
            <p>© {new Date().getFullYear()} BeteBrana Digital Library. All rights reserved.</p>
            <div className="flex gap-6">
              <a href="#" className="hover:text-zinc-600 transition-colors">Twitter</a>
              <a href="#" className="hover:text-zinc-600 transition-colors">Instagram</a>
              <a href="#" className="hover:text-zinc-600 transition-colors">LinkedIn</a>
            </div>
          </div>
        </footer>

      </div>
    </>
  );
}
