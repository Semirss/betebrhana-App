import { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { LogOut, Bookmark, Moon, Bell, Globe, Sun, ChevronRight } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

export default function SettingsPage() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const [isDark, setIsDark] = useState(() => localStorage.getItem('theme') === 'dark');
  const [notifications, setNotifications] = useState(() => localStorage.getItem('notifications') !== 'false');
  const [language, setLanguage] = useState(() => localStorage.getItem('language') || 'en');

  useEffect(() => {
    if (isDark) {
      document.documentElement.classList.add('dark');
      localStorage.setItem('theme', 'dark');
    } else {
      document.documentElement.classList.remove('dark');
      localStorage.setItem('theme', 'light');
    }
  }, [isDark]);

  useEffect(() => {
    localStorage.setItem('notifications', notifications.toString());
  }, [notifications]);

  useEffect(() => {
    localStorage.setItem('language', language);
  }, [language]);

  if (!user) {
    return (
      <div className="pt-32 pb-24 px-6 flex flex-col items-center justify-center min-h-[70vh] bg-[#FDFBF7]">
        <h2 className="text-2xl font-serif font-bold text-zinc-900 mb-4">You are not logged in</h2>
        <button onClick={() => navigate('/login')} className="px-8 py-3 bg-[#53389e] text-white rounded-full font-bold shadow-lg">
          Go to Login
        </button>
      </div>
    );
  }

  const Toggle = ({ enabled, setEnabled, id }) => (
    <button
      id={id}
      onClick={() => setEnabled(v => !v)}
      className={`relative inline-flex h-7 w-12 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 focus:outline-none ${enabled ? 'bg-[#53389e]' : 'bg-zinc-200'}`}
    >
      <span className={`pointer-events-none inline-block h-6 w-6 transform rounded-full bg-white shadow transition duration-200 ${enabled ? 'translate-x-5' : 'translate-x-0'}`} />
    </button>
  );

  return (
    <div className="min-h-screen bg-[#FDFBF7] pt-32 md:pt-36 pb-24 px-6 md:px-16">
      <div className="max-w-[1200px] mx-auto">

        {/* Page Header */}
        <div className="mb-10 pb-6 border-b border-zinc-200">
          <h1 className="text-4xl font-serif font-bold text-zinc-900 tracking-tight mb-1">Settings</h1>
          <p className="text-zinc-500">Manage your profile and personal preferences</p>
        </div>

        {/* Two-Column Desktop Layout */}
        <div className="grid grid-cols-1 lg:grid-cols-[280px_1fr] gap-10">

          {/* LEFT SIDEBAR — Profile Card */}
          <div className="h-fit">
            <div className="bg-white rounded-3xl p-8 shadow-sm border border-zinc-200 flex flex-col items-center text-center relative overflow-hidden">
              {/* Avatar */}
              <div className="w-24 h-24 rounded-full bg-gradient-to-br from-[#53389e] to-[#9b82ff] flex items-center justify-center text-white text-4xl font-serif border-4 border-white shadow-lg ring-4 ring-[#ede9fe] mb-5">
                {user.name?.charAt(0).toUpperCase() || 'U'}
              </div>
              <h2 className="text-xl font-bold text-zinc-900 mb-1">{user.name}</h2>
              <p className="text-sm text-zinc-500 mb-6 break-all">{user.email}</p>

              <div className="w-full h-px bg-zinc-100 mb-6" />

              {/* Sign Out */}
              <button
                onClick={logout}
                className="w-full flex items-center justify-center gap-2 py-3 bg-red-50 hover:bg-red-100 text-red-600 font-bold rounded-xl transition-colors border border-red-100"
              >
                <LogOut size={17} />
                Sign Out
              </button>

              {/* Decoration */}
              <div className="absolute -right-10 -top-10 w-40 h-40 bg-[#53389e]/5 rounded-full blur-2xl pointer-events-none" />
            </div>
          </div>

          {/* RIGHT CONTENT — Settings Panels */}
          <div className="flex flex-col gap-8">

            {/* Library */}
            <section>
              <h3 className="text-xs font-bold uppercase tracking-[0.15em] text-zinc-400 mb-4">Library</h3>
              <div className="bg-white rounded-2xl border border-zinc-200 shadow-sm overflow-hidden">
                <button
                  onClick={() => navigate('/library')}
                  className="w-full flex items-center gap-5 p-5 hover:bg-zinc-50 transition-colors group text-left"
                >
                  <div className="p-3 bg-blue-50 text-blue-600 rounded-xl group-hover:scale-105 transition-transform flex-shrink-0">
                    <Bookmark size={20} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <span className="font-bold text-zinc-900 block">My Rentals &amp; History</span>
                    <span className="text-sm text-zinc-500">View your active books and reading history</span>
                  </div>
                  <ChevronRight size={18} className="text-zinc-300 group-hover:text-zinc-500 flex-shrink-0 transition-colors" />
                </button>
              </div>
            </section>

            {/* Appearance & Notifications */}
            <section>
              <h3 className="text-xs font-bold uppercase tracking-[0.15em] text-zinc-400 mb-4">Preferences</h3>
              <div className="bg-white rounded-2xl border border-zinc-200 shadow-sm overflow-hidden divide-y divide-zinc-100">

                {/* Dark Mode */}
                <div className="flex items-center gap-5 p-5">
                  <div className={`p-3 rounded-xl flex-shrink-0 transition-colors ${isDark ? 'bg-zinc-800 text-yellow-300' : 'bg-amber-50 text-amber-500'}`}>
                    {isDark ? <Moon size={20} /> : <Sun size={20} />}
                  </div>
                  <div className="flex-1 min-w-0">
                    <span className="font-bold text-zinc-900 block">Dark Theme</span>
                    <span className="text-sm text-zinc-500">Currently {isDark ? 'enabled — dark mode is on' : 'disabled — using light mode'}</span>
                  </div>
                  <Toggle id="toggle-dark" enabled={isDark} setEnabled={setIsDark} />
                </div>

                {/* Notifications */}
                <div className="flex items-center gap-5 p-5">
                  <div className={`p-3 rounded-xl flex-shrink-0 transition-colors ${notifications ? 'bg-orange-50 text-orange-500' : 'bg-zinc-100 text-zinc-400'}`}>
                    <Bell size={20} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <span className="font-bold text-zinc-900 block">Push Notifications</span>
                    <span className="text-sm text-zinc-500">Get alerts for due dates and new arrivals</span>
                  </div>
                  <Toggle id="toggle-notifications" enabled={notifications} setEnabled={setNotifications} />
                </div>

                {/* Language */}
                <div className="flex items-center gap-5 p-5">
                  <div className="p-3 bg-teal-50 text-teal-600 rounded-xl flex-shrink-0">
                    <Globe size={20} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <span className="font-bold text-zinc-900 block">App Language</span>
                    <span className="text-sm text-zinc-500">Choose your preferred interface language</span>
                  </div>
                  <select
                    id="select-language"
                    value={language}
                    onChange={(e) => setLanguage(e.target.value)}
                    className="bg-zinc-100 text-zinc-800 font-bold text-sm px-4 py-2.5 rounded-xl border border-zinc-200 focus:ring-2 focus:ring-[#53389e] focus:outline-none cursor-pointer flex-shrink-0"
                  >
                    <option value="en">English (US)</option>
                    <option value="am">አማርኛ (Amharic)</option>
                  </select>
                </div>

              </div>
            </section>

          </div>
        </div>

      </div>
    </div>
  );
}
