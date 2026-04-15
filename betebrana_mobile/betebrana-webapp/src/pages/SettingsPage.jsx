import { useAuth } from '../context/AuthContext';
import { User as UserIcon, LogOut, ChevronRight, Bookmark, Settings, CheckCircle } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

export default function SettingsPage() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  if (!user) {
    return (
      <div className="pt-24 pb-24 px-6 flex flex-col items-center justify-center min-h-[70vh]">
        <h2 className="text-xl font-serif font-bold text-zinc-900 mb-4">You are not logged in</h2>
        <button 
          onClick={() => navigate('/login')}
          className="px-8 py-3 bg-zinc-900 text-white rounded-full font-bold shadow-lg"
        >
          Go to Login
        </button>
      </div>
    );
  }

  return (
    <div className="pt-12 pb-24 px-6 relative">
      <h1 className="text-3xl font-serif font-bold text-zinc-900 mb-8">
        Profile
      </h1>

      {/* User Card */}
      <div className="bg-white/70 backdrop-blur-md rounded-3xl p-6 shadow-sm border border-zinc-200/50 flex items-center gap-6 mb-8 relative overflow-hidden">
        <div className="w-20 h-20 rounded-full bg-gradient-to-tr from-primary to-orange-400 flex items-center justify-center text-white text-3xl font-serif shadow-inner">
          {user.name?.charAt(0).toUpperCase() || 'U'}
        </div>
        <div className="flex-1 relative z-10">
          <h2 className="text-xl font-serif font-bold text-zinc-900">{user.name}</h2>
          <p className="text-sm text-zinc-500">{user.email}</p>
        </div>
        
        {/* Subtle background decoration */}
        <div className="absolute -right-8 -top-8 w-32 h-32 bg-primary/5 rounded-full blur-2xl pointer-events-none"></div>
      </div>

      {/* Settings Menu */}
      <div className="bg-white/70 backdrop-blur-md rounded-3xl shadow-sm border border-zinc-200/50 overflow-hidden mb-8">
        <div className="flex items-center gap-4 p-4 border-b border-zinc-100 hover:bg-zinc-50/50 cursor-pointer transition-colors" onClick={() => navigate('/library')}>
          <div className="p-2 bg-blue-50 text-blue-500 rounded-xl"><Bookmark size={20} /></div>
          <span className="font-medium text-zinc-700 flex-1">My Rentals & Queue</span>
          <ChevronRight size={20} className="text-zinc-300" />
        </div>
        <div className="flex items-center gap-4 p-4 border-b border-zinc-100 hover:bg-zinc-50/50 cursor-pointer transition-colors">
          <div className="p-2 bg-purple-50 text-purple-500 rounded-xl"><CheckCircle size={20} /></div>
          <span className="font-medium text-zinc-700 flex-1">Subscription / Payments</span>
          <ChevronRight size={20} className="text-zinc-300" />
        </div>
        <div className="flex items-center gap-4 p-4 hover:bg-zinc-50/50 cursor-pointer transition-colors">
          <div className="p-2 bg-zinc-100 text-zinc-600 rounded-xl"><Settings size={20} /></div>
          <span className="font-medium text-zinc-700 flex-1">App Preferences</span>
          <ChevronRight size={20} className="text-zinc-300" />
        </div>
      </div>

      {/* Logout Button */}
      <button 
        onClick={logout}
        className="w-full flex items-center justify-center gap-2 py-4 bg-red-50 hover:bg-red-100 text-red-500 font-bold rounded-2xl transition-colors border border-red-100/50"
      >
        <LogOut size={20} />
        Sign Out
      </button>

    </div>
  );
}
