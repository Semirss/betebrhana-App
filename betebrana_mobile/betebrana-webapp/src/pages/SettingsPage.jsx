import { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { useTheme } from '../context/ThemeContext';
import { useLanguage } from '../context/LanguageContext';
import { LogOut, Bookmark, Moon, Globe, Sun, ChevronRight } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

export default function SettingsPage() {
  const { user, logout } = useAuth();
  const [isLangOpen, setIsLangOpen] = useState(false);
  const navigate = useNavigate();
  const { isDark, setIsDark } = useTheme();
  const { language, setLanguage, t } = useLanguage();

  if (!user) {
    return (
      <div className="pt-32 pb-24 px-6 flex flex-col items-center justify-center min-h-[70vh] bg-[#F7F5F5] dark:bg-[#121212] transition-colors">
        <h2 className="text-2xl font-serif font-bold text-zinc-900 dark:text-zinc-100 mb-4">{t('You are not logged in')}</h2>
        <button onClick={() => navigate('/login')} className="px-8 py-3 bg-[#EC7D22]/85 backdrop-blur-sm text-white rounded-full font-bold shadow-lg">
          {t('Go to Login')}
        </button>
      </div>
    );
  }

  const Toggle = ({ enabled, setEnabled, id }) => (
    <button
      id={id}
      onClick={() => setEnabled(v => !v)}
      className={`relative inline-flex h-7 w-12 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 focus:outline-none ${enabled ? 'bg-[#EC7D22]/85 backdrop-blur-sm' : 'bg-zinc-200 dark:bg-zinc-700'}`}
    >
      <span className={`pointer-events-none inline-block h-6 w-6 transform rounded-full bg-white shadow transition duration-200 ${enabled ? 'translate-x-5' : 'translate-x-0'}`} />
    </button>
  );

  return (
    <div className="min-h-screen bg-[#F7F5F5] dark:bg-[#121212] pt-4 md:pt-36 pb-24 px-6 md:px-16 transition-colors">
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
            <div className="bg-white/80 dark:bg-[#1e1e1e]/80 backdrop-blur-xl rounded-[2.5rem] p-10 shadow-xl border border-white/60 dark:border-zinc-800 flex flex-col items-center text-center relative overflow-hidden transition-all hover:shadow-2xl hover:-translate-y-1">
              {/* Avatar */}
              <div className="w-28 h-28 rounded-full bg-gradient-to-br from-[#EC7D22] to-[#FDBA74] flex items-center justify-center text-white text-5xl font-serif border-4 border-white dark:border-[#1e1e1e] shadow-xl ring-4 ring-[#FFF7ED] dark:ring-zinc-800 mb-6 z-10 transition-colors">
                {user.name?.charAt(0).toUpperCase() || 'U'}
              </div>
              <h2 className="text-2xl font-bold text-zinc-900 dark:text-zinc-100 mb-1 z-10">{user.name}</h2>
              <p className="text-[15px] text-zinc-500 dark:text-zinc-400 mb-8 break-all z-10">{user.email}</p>

              {/* Sign Out */}
              <button
                onClick={logout}
                className="w-full flex items-center justify-center gap-2 py-4 bg-red-50 dark:bg-red-900/30 hover:bg-red-100 dark:hover:bg-red-900/50 text-red-600 dark:text-red-400 font-bold rounded-full transition-all border border-red-100 dark:border-red-900/50 z-10"
              >
                <LogOut size={17} />
                {t('Sign Out')}
              </button>

              {/* Decoration */}
              <div className="absolute -right-10 -top-10 w-40 h-40 bg-[#EC7D22]/5 dark:bg-[#EC7D22]/20 rounded-full blur-2xl pointer-events-none" />
            </div>
          </div>

          {/* RIGHT CONTENT — Settings Panels */}
          <div className="flex flex-col gap-8">

            {/* Library */}
            <section>
              <h3 className="text-xs font-bold uppercase tracking-[0.15em] text-zinc-400 dark:text-zinc-500 mb-4 px-2">{t('Library')}</h3>
              <div className="flex flex-col gap-4">
                <button
                  onClick={() => navigate('/library')}
                  className="w-full flex items-center gap-5 p-4 bg-white dark:bg-[#1e1e1e] rounded-[2rem] border border-white/50 dark:border-zinc-800 shadow-md hover:shadow-lg hover:-translate-y-0.5 transition-all group text-left"
                >
                  <div className="w-14 h-14 flex items-center justify-center bg-blue-50 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 rounded-full group-hover:scale-105 transition-transform flex-shrink-0">
                    <Bookmark size={22} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <span className="font-bold text-zinc-900 dark:text-zinc-100 block text-lg">{t('My Rentals & History')}</span>
                    <span className="text-sm text-zinc-500 dark:text-zinc-400">{t('View your active books and reading history')}</span>
                  </div>
                  <div className="w-10 h-10 flex items-center justify-center rounded-full bg-zinc-50 dark:bg-zinc-800/50 group-hover:bg-[#EC7D22]/10 group-hover:text-[#EC7D22] transition-colors">
                    <ChevronRight size={18} className="flex-shrink-0 transition-colors" />
                  </div>
                </button>
              </div>
            </section>

            {/* Appearance & Preferences */}
            <section>
              <h3 className="text-xs font-bold uppercase tracking-[0.15em] text-zinc-400 dark:text-zinc-500 mb-4 px-2">{t('Preferences')}</h3>
              <div className="flex flex-col gap-4">

                {/* Dark Mode */}
                <div className="flex items-center gap-5 p-4 bg-white dark:bg-[#1e1e1e] rounded-[2rem] border border-white/50 dark:border-zinc-800 shadow-md transition-all hover:shadow-lg hover:-translate-y-0.5">
                  <div className={`w-14 h-14 flex items-center justify-center rounded-full flex-shrink-0 transition-colors ${isDark ? 'bg-zinc-800 text-yellow-300' : 'bg-amber-50 text-amber-500'}`}>
                    {isDark ? <Moon size={22} /> : <Sun size={22} />}
                  </div>
                  <div className="flex-1 min-w-0">
                    <span className="font-bold text-zinc-900 dark:text-zinc-100 block text-lg">{t('Dark Theme')}</span>
                    <span className="text-sm text-zinc-500 dark:text-zinc-400">{isDark ? t('Currently enabled — dark mode is on') : t('Currently disabled — using light mode')}</span>
                  </div>
                  <Toggle id="toggle-dark" enabled={isDark} setEnabled={setIsDark} />
                </div>

                {/* Language */}
                <div className="flex items-center gap-5 p-4 bg-white dark:bg-[#1e1e1e] rounded-[2rem] border border-white/50 dark:border-zinc-800 shadow-md transition-all hover:shadow-lg hover:-translate-y-0.5">
                  <div className="w-14 h-14 flex items-center justify-center bg-teal-50 dark:bg-teal-900/30 text-teal-600 dark:text-teal-400 rounded-full flex-shrink-0">
                    <Globe size={22} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <span className="font-bold text-zinc-900 dark:text-zinc-100 block text-lg">{t('App Language')}</span>
                    <span className="text-sm text-zinc-500 dark:text-zinc-400">{t('Choose your preferred interface language')}</span>
                  </div>
                  <div className="relative flex-shrink-0">
                    <button
                      onClick={() => setIsLangOpen(!isLangOpen)}
                      className="bg-zinc-100 dark:bg-zinc-800 text-zinc-800 dark:text-zinc-100 font-bold text-[15px] px-6 py-3.5 rounded-full border border-zinc-200 dark:border-zinc-700 focus:ring-4 focus:ring-[#EC7D22]/20 focus:border-[#EC7D22] outline-none flex items-center justify-between gap-3 min-w-[180px] transition-all z-10"
                    >
                      <span>{language === 'am' ? 'አማርኛ (Amharic)' : 'English (US)'}</span>
                      <ChevronRight size={18} className={`transition-transform duration-200 ${isLangOpen ? 'rotate-90' : 'rotate-0'}`} />
                    </button>

                    {/* Dropdown Menu */}
                    {isLangOpen && (
                      <>
                        <div 
                          className="fixed inset-0 z-40" 
                          onClick={() => setIsLangOpen(false)} 
                        />
                        <div className="absolute right-0 top-full mt-2 w-full min-w-[180px] bg-white dark:bg-[#1e1e1e] rounded-[2rem] p-2 shadow-2xl border border-zinc-200 dark:border-zinc-700 z-50 flex flex-col gap-1 overflow-hidden animate-in fade-in zoom-in-95 duration-200">
                          <button
                            onClick={() => { setLanguage('en'); setIsLangOpen(false); }}
                            className={`px-5 py-3 text-left rounded-[1.5rem] font-bold text-sm transition-all ${language === 'en' ? 'bg-[#EC7D22]/10 text-[#EC7D22]' : 'text-zinc-700 dark:text-zinc-300 hover:bg-zinc-100 dark:hover:bg-zinc-800'}`}
                          >
                            English (US)
                          </button>
                          <button
                            onClick={() => { setLanguage('am'); setIsLangOpen(false); }}
                            className={`px-5 py-3 text-left rounded-[1.5rem] font-bold text-sm transition-all ${language === 'am' ? 'bg-[#EC7D22]/10 text-[#EC7D22]' : 'text-zinc-700 dark:text-zinc-300 hover:bg-zinc-100 dark:hover:bg-zinc-800'}`}
                          >
                            አማርኛ (Amharic)
                          </button>
                        </div>
                      </>
                    )}
                  </div>
                </div>

              </div>
            </section>

          </div>
        </div>

      </div>
    </div>
  );
}
