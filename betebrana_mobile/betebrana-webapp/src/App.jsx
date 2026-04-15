import { BrowserRouter as Router, Routes, Route, Link, useLocation } from 'react-router-dom';
import { Home, Compass, Search, User, BookOpen } from 'lucide-react';
import { AuthProvider } from './context/AuthContext';

import HomePage from './pages/HomePage';
import DiscoverPage from './pages/HomePage'; // Alias
import SearchPage from './pages/SearchPage';
import LibraryPage from './pages/LibraryPage';
import BookDetailsPage from './pages/BookDetailsPage';
import LoginPage from './pages/LoginPage';
import ReaderPage from './pages/ReaderPage';
import SettingsPage from './pages/SettingsPage';

function BottomNav() {
  const location = useLocation();
  const path = location.pathname;

  // Do not show bottom nav on details or reader
  if (path.includes('/book/')) return null;

  return (
    <nav className="bottom-nav">
      <Link to="/" className={`nav-item ${path === '/' ? 'active' : ''}`}>
        <Home size={24} />
        <span className="text-[10px] mt-1">Discover</span>
      </Link>
      <Link to="/search" className={`nav-item ${path === '/search' ? 'active' : ''}`}>
        <Search size={24} />
        <span className="text-[10px] mt-1">Search</span>
      </Link>
      <Link to="/library" className={`nav-item ${path === '/library' ? 'active' : ''}`}>
        <BookOpen size={24} />
        <span className="text-[10px] mt-1">Library</span>
      </Link>
      <Link to="/profile" className={`nav-item ${path === '/profile' ? 'active' : ''}`}>
        <User size={24} />
        <span className="text-[10px] mt-1">Settings</span>
      </Link>
    </nav>
  );
}

function App() {
  return (
    <AuthProvider>
      <Router>
        <div className="flex justify-center min-h-screen w-full items-center">
          <div className="app-container flex flex-col">
            <div className="flex-1 relative overflow-x-hidden overflow-y-auto w-full no-scrollbar">
              <Routes>
                <Route path="/" element={<HomePage />} />
                <Route path="/discover" element={<DiscoverPage />} />
                <Route path="/search" element={<SearchPage />} />
                <Route path="/library" element={<LibraryPage />} />
                <Route path="/profile" element={<SettingsPage />} />
                
                <Route path="/book/:id" element={<BookDetailsPage />} />
                <Route path="/read/:id" element={<ReaderPage />} />
                <Route path="/login" element={<LoginPage />} />
              </Routes>
            </div>
            <BottomNav />
          </div>
        </div>
      </Router>
    </AuthProvider>
  );
}

export default App;
