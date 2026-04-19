import { BrowserRouter as Router, Routes, Route, NavLink, useLocation, useNavigate } from 'react-router-dom';
import { Home, Search, BookOpen, User, BookMarked, Monitor, Sun, Moon } from 'lucide-react';
import { AuthProvider, useAuth } from './context/AuthContext';
import { ThemeProvider, useTheme } from './context/ThemeContext';
import { LanguageProvider, useLanguage } from './context/LanguageContext';

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
  const { t } = useLanguage();
  const navigate = useNavigate();

  if (pathname.startsWith('/read/')) return null;

  return (
    <header className="topnav hidden md:flex items-center justify-between px-16 py-4 fixed top-0 w-full z-[100] bg-[#FDFBF7]/80 dark:bg-[#121212]/80 backdrop-blur-lg border-b border-zinc-200/50 dark:border-zinc-800/50 shadow-sm transition-all">
      <div className="flex items-center gap-2 cursor-pointer" onClick={() => navigate('/')}>
        <div className="w-8 h-8 rounded-lg bg-[#53389e] flex items-center justify-center text-white shadow-md">
          <BookMarked size={18} />
        </div>
        <span className="font-bold text-xl text-zinc-900 dark:text-zinc-100 tracking-tight">BeteBrana</span>
      </div>

      <nav className="flex items-center gap-10">
        <NavLink to="/" className={({isActive}) => `text-[15px] font-medium transition-colors ${isActive ? 'text-[#53389e] dark:text-[#a78bfa]' : 'text-zinc-500 dark:text-zinc-400 hover:text-zinc-900 dark:hover:text-zinc-100'}`}>{t('Home')}</NavLink>
        <NavLink to="/search" className={({isActive}) => `text-[15px] font-medium transition-colors ${isActive ? 'text-[#53389e] dark:text-[#a78bfa]' : 'text-zinc-500 dark:text-zinc-400 hover:text-zinc-900 dark:hover:text-zinc-100'}`}>{t('Discover')}</NavLink>
        <NavLink to="/library" className={({isActive}) => `text-[15px] font-medium transition-colors ${isActive ? 'text-[#53389e] dark:text-[#a78bfa]' : 'text-zinc-500 dark:text-zinc-400 hover:text-zinc-900 dark:hover:text-zinc-100'}`}>{t('My Library')}</NavLink>
      </nav>

      <div>
        {user ? (
          <button onClick={() => navigate('/profile')} className="px-6 py-2.5 bg-[#bbf7d0] dark:bg-emerald-900 hover:bg-[#86efac] dark:hover:bg-emerald-800 text-[#166534] dark:text-emerald-100 rounded-full text-sm font-bold transition-all border border-[#4ade80] dark:border-emerald-700">
            {t('My Account')}
          </button>
        ) : (
          <button onClick={() => navigate('/login')} className="px-6 py-2.5 bg-[#bbf7d0] dark:bg-emerald-900 hover:bg-[#86efac] dark:hover:bg-emerald-800 text-[#166534] dark:text-emerald-100 rounded-full text-sm font-bold transition-all border border-[#4ade80] dark:border-emerald-700">
            {t('Sign In')}
          </button>
        )}
      </div>
    </header>
  );
}

function BottomNav() {
  const { pathname } = useLocation();
  const { t } = useLanguage();
  if (pathname.startsWith('/read/')) return null;
  return (
    <nav className="bottom-nav md:hidden z-50 bg-white dark:bg-[#1e1e1e] border-t border-zinc-200 dark:border-zinc-800 transition-colors">
      {[
        { to: '/',        icon: Home,     label: 'Discover' },
        { to: '/search',  icon: Search,   label: 'Search'   },
        { to: '/library', icon: BookOpen, label: 'Library'  },
        { to: '/profile', icon: User,     label: 'Profile'  },
      ].map(({ to, icon: Icon, label }) => (
        <NavLink key={to} to={to} end={to === '/'} className={({ isActive }) => `nav-item${isActive ? ' active dark:text-[#a78bfa]' : ' dark:text-zinc-400'} flex flex-col items-center p-2`}>
          <Icon size={22} />
          <span className="nav-label text-xs mt-1 font-medium">{t(label)}</span>
        </NavLink>
      ))}
    </nav>
  );
}

function AppLayout() {
  return (
    <div className="app-root bg-[#FDFBF7] dark:bg-[#121212] min-h-screen transition-colors duration-200">
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
    <ThemeProvider>
      <LanguageProvider>
        <AuthProvider>
          <Router>
            <AppLayout />
          </Router>
        </AuthProvider>
      </LanguageProvider>
    </ThemeProvider>
  );
}
