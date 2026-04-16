import { BrowserRouter as Router, Routes, Route, NavLink, useLocation, useNavigate } from 'react-router-dom';
import { Home, Search, BookOpen, User, BookMarked, Monitor, Sun, Moon } from 'lucide-react';
import { AuthProvider, useAuth } from './context/AuthContext';

import HomePage        from './pages/HomePage';
import SearchPage      from './pages/SearchPage';
import LibraryPage     from './pages/LibraryPage';
import BookDetailsPage from './pages/BookDetailsPage';
import LoginPage       from './pages/LoginPage';
import ReaderPage      from './pages/ReaderPage';
import SettingsPage    from './pages/SettingsPage';

function TopNav() {
  const { pathname } = useLocation();
  const { user } = useAuth();
  const navigate = useNavigate();

  if (pathname.startsWith('/read/')) return null;

  return (
    <header className="topnav hidden md:flex items-center justify-between px-16 py-6 absolute top-0 w-full z-50">
      <div className="flex items-center gap-2 cursor-pointer" onClick={() => navigate('/')}>
        <div className="w-8 h-8 rounded-lg bg-[#53389e] flex items-center justify-center text-white">
          <BookMarked size={18} />
        </div>
        <span className="font-bold text-xl text-zinc-900 tracking-tight">BeteBrana</span>
      </div>

      <nav className="flex items-center gap-10">
        <NavLink to="/" className={({isActive}) => `text-[15px] font-medium transition-colors ${isActive ? 'text-[#53389e]' : 'text-zinc-500 hover:text-zinc-900'}`}>Home</NavLink>
        <NavLink to="/search" className={({isActive}) => `text-[15px] font-medium transition-colors ${isActive ? 'text-[#53389e]' : 'text-zinc-500 hover:text-zinc-900'}`}>Discover</NavLink>
        <NavLink to="/library" className={({isActive}) => `text-[15px] font-medium transition-colors ${isActive ? 'text-[#53389e]' : 'text-zinc-500 hover:text-zinc-900'}`}>My Library</NavLink>
      </nav>

      <div>
        {user ? (
          <button onClick={() => navigate('/profile')} className="px-6 py-2.5 bg-[#bbf7d0] hover:bg-[#86efac] text-[#166534] rounded-full text-sm font-bold transition-all border border-[#4ade80]">
            My Account
          </button>
        ) : (
          <button onClick={() => navigate('/login')} className="px-6 py-2.5 bg-[#bbf7d0] hover:bg-[#86efac] text-[#166534] rounded-full text-sm font-bold transition-all border border-[#4ade80]">
            Sign In
          </button>
        )}
      </div>
    </header>
  );
}

function BottomNav() {
  const { pathname } = useLocation();
  if (pathname.startsWith('/read/')) return null;
  return (
    <nav className="bottom-nav md:hidden z-50">
      {[
        { to: '/',        icon: Home,     label: 'Discover' },
        { to: '/search',  icon: Search,   label: 'Search'   },
        { to: '/library', icon: BookOpen, label: 'Library'  },
        { to: '/profile', icon: User,     label: 'Profile'  },
      ].map(({ to, icon: Icon, label }) => (
        <NavLink key={to} to={to} end={to === '/'} className={({ isActive }) => `nav-item${isActive ? ' active' : ''}`}>
          <Icon size={22} />
          <span className="nav-label">{label}</span>
        </NavLink>
      ))}
    </nav>
  );
}

function AppLayout() {
  return (
    <div className="app-root bg-[#FDFBF7]">
      <TopNav />
      <main className="main-content">
        <Routes>
          <Route path="/"          element={<HomePage />} />
          <Route path="/discover"  element={<HomePage />} />
          <Route path="/search"    element={<SearchPage />} />
          <Route path="/library"   element={<LibraryPage />} />
          <Route path="/profile"   element={<SettingsPage />} />
          <Route path="/book/:id"  element={<BookDetailsPage />} />
          <Route path="/read/:id"  element={<ReaderPage />} />
          <Route path="/login"     element={<LoginPage />} />
        </Routes>
      </main>
      <BottomNav />
    </div>
  );
}

export default function App() {
  return (
    <AuthProvider>
      <Router>
        <AppLayout />
      </Router>
    </AuthProvider>
  );
}
