import { BrowserRouter as Router, Routes, Route, NavLink, useLocation } from 'react-router-dom';
import { Home, Search, BookOpen, User, BookMarked } from 'lucide-react';
import { AuthProvider } from './context/AuthContext';

import HomePage from './pages/HomePage';
import SearchPage from './pages/SearchPage';
import LibraryPage from './pages/LibraryPage';
import BookDetailsPage from './pages/BookDetailsPage';
import LoginPage from './pages/LoginPage';
import ReaderPage from './pages/ReaderPage';
import SettingsPage from './pages/SettingsPage';

const NAV_LINKS = [
  { to: '/',        icon: Home,     label: 'Discover' },
  { to: '/search',  icon: Search,   label: 'Search'   },
  { to: '/library', icon: BookOpen, label: 'Library'  },
  { to: '/profile', icon: User,     label: 'Profile'  },
];

/* ─── Desktop left sidebar ─── */
function Sidebar() {
  const { pathname } = useLocation();
  if (pathname.startsWith('/book/') || pathname.startsWith('/read/')) return null;

  return (
    <aside className="desktop-sidebar">
      {/* Logo */}
      <div className="sidebar-logo">
        <BookMarked size={26} className="sidebar-logo-icon" />
        <span className="sidebar-logo-text">BeteBrana</span>
      </div>

      {/* Primary nav */}
      <nav className="sidebar-nav">
        {NAV_LINKS.map(({ to, icon: Icon, label }) => (
          <NavLink
            key={to}
            to={to}
            end={to === '/'}
            className={({ isActive }) => `sidebar-nav-item${isActive ? ' active' : ''}`}
          >
            <Icon size={20} />
            <span>{label}</span>
          </NavLink>
        ))}
      </nav>

      {/* Library quick-links divider */}
      <div className="sidebar-divider" />
      <p className="sidebar-section-label">Your Library</p>
      <div className="sidebar-library-hint">
        Books you've saved appear here.
      </div>
    </aside>
  );
}

/* ─── Mobile bottom nav ─── */
function BottomNav() {
  const { pathname } = useLocation();
  if (pathname.startsWith('/book/') || pathname.startsWith('/read/')) return null;

  return (
    <nav className="bottom-nav">
      {NAV_LINKS.map(({ to, icon: Icon, label }) => (
        <NavLink
          key={to}
          to={to}
          end={to === '/'}
          className={({ isActive }) => `nav-item${isActive ? ' active' : ''}`}
        >
          <Icon size={22} />
          <span className="nav-label">{label}</span>
        </NavLink>
      ))}
    </nav>
  );
}

/* ─── Inner layout — needs Router context ─── */
function AppLayout() {
  return (
    <div className="app-root">
      <Sidebar />

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
