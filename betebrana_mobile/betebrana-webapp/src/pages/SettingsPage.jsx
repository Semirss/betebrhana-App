import { useAuth } from '../context/AuthContext';
import { useTheme } from '../context/ThemeContext';
import { useLanguage } from '../context/LanguageContext';
import { LogOut, Bookmark, Moon, Globe, Sun, ChevronRight } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

export default function SettingsPage() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const { isDark, setIsDark } = useTheme();
  const { language, setLanguage, t } = useLanguage();

  if (!user) {
    return (
      <div className="pt-32 pb-24 px-6 flex flex-col items-center justify-center min-h-[70vh] bg-[#FDFBF7] dark:bg-[#121212] transition-colors">
        <h2 className="text-2xl font-serif font-bold text-zinc-900 dark:text-zinc-100 mb-4">{t('You are not logged in')}</h2>
        <button onClick={() => navigate('/login')} className="px-8 py-3 bg-[#53389e] text-white rounded-full font-bold shadow-lg">
          {t('Go to Login')}
        </button>
      </div>
    );
  }

  const Toggle = ({ enabled, setEnabled, id }) => (
    <button
      id={id}
      onClick={() => setEnabled(v => !v)}
      className={`relative inline-flex h-7 w-12 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 focus:outline-none ${enabled ? 'bg-[#53389e]' : 'bg-zinc-200 dark:bg-zinc-700'}`}
    >
      <span className={`pointer-events-none inline-block h-6 w-6 transform rounded-full bg-white shadow transition duration-200 ${enabled ? 'translate-x-5' : 'translate-x-0'}`} />
    </button>
  );

  return (
    <div className="min-h-screen bg-[#FDFBF7] dark:bg-[#121212] pt-4 md:pt-36 pb-24 px-6 md:px-16 transition-colors">
      <div className="max-w-[1200px] mx-auto">

        {/* Page Header */}
        <div className="mb-10 pb-6 border-b border-zinc-200 dark:border-zinc-800">
          <h1 className="text-4xl font-serif font-bold text-zinc-900 dark:text-zinc-100 tracking-tight mb-1">{t('Settings')}</h1>
          <p className="text-zinc-500 dark:text-zinc-400">{t('Manage your profile and personal preferences')}</p>
        </div>

        {/* Two-Column Desktop Layout */}
        <div className="grid grid-cols-1 lg:grid-cols-[280px_1fr] gap-10">

          {/* LEFT SIDEBAR — Profile Card */}
          <div className="h-fit">
            <div className="bg-white dark:bg-[#1e1e1e] rounded-3xl p-8 shadow-sm border border-zinc-200 dark:border-zinc-800 flex flex-col items-center text-center relative overflow-hidden transition-colors">
              {/* Avatar */}
              <div className="w-24 h-24 rounded-full bg-gradient-to-br from-[#53389e] to-[#9b82ff] flex items-center justify-center text-white text-4xl font-serif border-4 border-white dark:border-[#1e1e1e] shadow-lg ring-4 ring-[#ede9fe] dark:ring-zinc-800 mb-5 z-10 transition-colors">
                {user.name?.charAt(0).toUpperCase() || 'U'}
              </div>
              <h2 className="text-xl font-bold text-zinc-900 dark:text-zinc-100 mb-1 z-10">{user.name}</h2>
              <p className="text-sm text-zinc-500 dark:text-zinc-400 mb-6 break-all z-10">{user.email}</p>

              <div className="w-full h-px bg-zinc-100 dark:bg-zinc-800 mb-6 z-10 transition-colors" />

              {/* Sign Out */}
              <button
                onClick={logout}
                className="w-full flex items-center justify-center gap-2 py-3 bg-red-50 dark:bg-red-900/30 hover:bg-red-100 dark:hover:bg-red-900/50 text-red-600 dark:text-red-400 font-bold rounded-xl transition-colors border border-red-100 dark:border-red-900/50 z-10"
              >
                <LogOut size={17} />
                {t('Sign Out')}
              </button>

              {/* Decoration */}
              <div className="absolute -right-10 -top-10 w-40 h-40 bg-[#53389e]/5 dark:bg-[#53389e]/20 rounded-full blur-2xl pointer-events-none" />
            </div>
          </div>

          {/* RIGHT CONTENT — Settings Panels */}
          <div className="flex flex-col gap-8">

            {/* Library */}
            <section>
              <h3 className="text-xs font-bold uppercase tracking-[0.15em] text-zinc-400 dark:text-zinc-500 mb-4">{t('Library')}</h3>
              <div className="bg-white dark:bg-[#1e1e1e] rounded-2xl border border-zinc-200 dark:border-zinc-800 shadow-sm overflow-hidden transition-colors">
                <button
                  onClick={() => navigate('/library')}
                  className="w-full flex items-center gap-5 p-5 hover:bg-zinc-50 dark:hover:bg-zinc-800/50 transition-colors group text-left"
                >
                  <div className="p-3 bg-blue-50 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 rounded-xl group-hover:scale-105 transition-transform flex-shrink-0">
                    <Bookmark size={20} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <span className="font-bold text-zinc-900 dark:text-zinc-100 block">{t('My Rentals & History')}</span>
                    <span className="text-sm text-zinc-500 dark:text-zinc-400">{t('View your active books and reading history')}</span>
                  </div>
                  <ChevronRight size={18} className="text-zinc-300 dark:text-zinc-600 group-hover:text-zinc-500 dark:group-hover:text-zinc-400 flex-shrink-0 transition-colors" />
                </button>
              </div>
            </section>

            {/* Appearance & Preferences */}
            <section>
              <h3 className="text-xs font-bold uppercase tracking-[0.15em] text-zinc-400 dark:text-zinc-500 mb-4">{t('Preferences')}</h3>
              <div className="bg-white dark:bg-[#1e1e1e] rounded-2xl border border-zinc-200 dark:border-zinc-800 shadow-sm overflow-hidden divide-y divide-zinc-100 dark:divide-zinc-800 transition-colors">

                {/* Dark Mode */}
                <div className="flex items-center gap-5 p-5">
                  <div className={`p-3 rounded-xl flex-shrink-0 transition-colors ${isDark ? 'bg-zinc-800 text-yellow-300' : 'bg-amber-50 text-amber-500'}`}>
                    {isDark ? <Moon size={20} /> : <Sun size={20} />}
                  </div>
                  <div className="flex-1 min-w-0">
                    <span className="font-bold text-zinc-900 dark:text-zinc-100 block">{t('Dark Theme')}</span>
                    <span className="text-sm text-zinc-500 dark:text-zinc-400">{isDark ? t('Currently enabled — dark mode is on') : t('Currently disabled — using light mode')}</span>
                  </div>
                  <Toggle id="toggle-dark" enabled={isDark} setEnabled={setIsDark} />
                </div>

                {/* Language */}
                <div className="flex items-center gap-5 p-5">
                  <div className="p-3 bg-teal-50 dark:bg-teal-900/30 text-teal-600 dark:text-teal-400 rounded-xl flex-shrink-0">
                    <Globe size={20} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <span className="font-bold text-zinc-900 dark:text-zinc-100 block">{t('App Language')}</span>
                    <span className="text-sm text-zinc-500 dark:text-zinc-400">{t('Choose your preferred interface language')}</span>
                  </div>
                  <select
                    id="select-language"
                    value={language}
                    onChange={(e) => setLanguage(e.target.value)}
                    className="bg-zinc-100 dark:bg-zinc-800 text-zinc-800 dark:text-zinc-100 font-bold text-sm px-4 py-2.5 rounded-xl border border-zinc-200 dark:border-zinc-700 focus:ring-2 focus:ring-[#53389e] focus:outline-none cursor-pointer flex-shrink-0 transition-colors"
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
