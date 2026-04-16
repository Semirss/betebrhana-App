import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { BookMarked, Mail, Lock, User, Eye, EyeOff, ArrowRight } from 'lucide-react';
import api from '../api';
import { useAuth } from '../context/AuthContext';

const PH = 'https://placehold.co/300x450/ede9fe/53389e?text=📖';

const SAMPLE_BOOKS = [
  { title: 'ሐሙስ', color: '#ede9fe' },
  { title: 'ቶቢያ', color: '#bbf7d0' },
  { title: 'ፍቅር እስከ መቃብር', color: '#fef9c3' },
  { title: 'አዲስ አበባ', color: '#fee2e2' },
];

export default function LoginPage() {
  const [tab, setTab] = useState('login'); // 'login' | 'register'
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPass, setShowPass] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();
  const { login } = useAuth();

  const handleLogin = async (e) => {
    e.preventDefault();
    setError(''); setSuccess('');
    setLoading(true);
    try {
      const res = await api.post('/auth/login', { email, password });
      const { token, user } = res.data;
      if (token) { login(user, token); navigate('/'); }
      else setError('Login failed. No token received.');
    } catch (err) {
      setError(err.response?.data?.error || err.response?.data?.message || 'Invalid credentials. Please try again.');
    } finally { setLoading(false); }
  };

  const handleRegister = async (e) => {
    e.preventDefault();
    setError(''); setSuccess('');
    if (!name.trim()) { setError('Please enter your full name.'); return; }
    setLoading(true);
    try {
      const res = await api.post('/auth/register', { email, password, name });
      const { token, user } = res.data;
      if (token) { login(user, token); navigate('/'); }
      else { setSuccess('Account created! Please log in.'); setTab('login'); }
    } catch (err) {
      setError(err.response?.data?.error || err.response?.data?.message || 'Registration failed. Please try again.');
    } finally { setLoading(false); }
  };

  return (
    <div className="min-h-screen bg-[#FDFBF7] flex">
      
      {/* LEFT PANEL — Branding */}
      <div className="hidden lg:flex lg:w-[45%] bg-[#53389e] flex-col justify-between p-14 relative overflow-hidden">
        
        {/* Logo */}
        <div className="flex items-center gap-3 z-10 relative">
          
        </div>

        {/* Center Content */}
        <div className="relative z-10">
          <h2 className="text-5xl font-serif font-bold text-white leading-tight mb-6">
            Your digital<br />library awaits.
          </h2>
          <p className="text-purple-200 text-lg leading-relaxed mb-12">
            Discover thousands of books. Borrow, read, and explore<br />at your own pace. Anytime, anywhere.
          </p>

         

          {/* Stats */}
          <div className="flex gap-8 mt-10">
            <div>
              <div className="text-3xl font-bold text-white">13+</div>
              <div className="text-purple-300 text-sm mt-1">Books Available</div>
            </div>
            <div>
              <div className="text-3xl font-bold text-white">1K+</div>
              <div className="text-purple-300 text-sm mt-1">Active Readers</div>
            </div>
          </div>
        </div>

        <Link to="/" className="text-purple-300 hover:text-white text-sm font-medium transition-colors z-10 relative">
          ← Back to Home
        </Link>

        {/* Large background decoration circles */}
        <div className="absolute -top-32 -right-32 w-96 h-96 bg-white/5 rounded-full pointer-events-none" />
        <div className="absolute bottom-0 -left-32 w-80 h-80 bg-white/5 rounded-full pointer-events-none" />
      </div>

      {/* RIGHT PANEL — Form */}
      <div className="flex-1 flex items-center justify-center px-8 py-16">
        <div className="w-full max-w-[440px]">
          
          {/* Mobile Logo */}
          <div className="flex items-center gap-2 mb-10 lg:hidden">
            <div className="w-9 h-9 bg-[#53389e] rounded-xl flex items-center justify-center text-white">
              <BookMarked size={18} />
            </div>
            <span className="font-bold text-xl text-zinc-900 tracking-tight">BeteBrana</span>
          </div>

          <div className="mb-8">
            <h1 className="text-3xl font-serif font-bold text-zinc-900 mb-2">
              {tab === 'login' ? 'Welcome back' : 'Create account'}
            </h1>
            <p className="text-zinc-500">
              {tab === 'login' ? 'Sign in to access your library.' : 'Join BeteBrana for free.'}
            </p>
          </div>

          {/* Tabs */}
          <div className="flex bg-zinc-100 rounded-2xl p-1 mb-8">
            {['login', 'register'].map((t) => (
              <button
                key={t}
                onClick={() => { setTab(t); setError(''); setSuccess(''); }}
                className={`flex-1 py-2.5 rounded-xl text-sm font-bold transition-all capitalize ${
                  tab === t ? 'bg-white text-zinc-900 shadow-sm' : 'text-zinc-500 hover:text-zinc-700'
                }`}
              >
                {t === 'login' ? 'Sign In' : 'Register'}
              </button>
            ))}
          </div>

          {/* Error / Success */}
          {error && (
            <div className="mb-6 p-4 bg-red-50 border border-red-100 text-red-600 rounded-2xl text-sm font-medium">
              {error}
            </div>
          )}
          {success && (
            <div className="mb-6 p-4 bg-[#bbf7d0] border border-green-200 text-green-700 rounded-2xl text-sm font-medium">
              {success}
            </div>
          )}

          {/* Form */}
          <form onSubmit={tab === 'login' ? handleLogin : handleRegister} className="flex flex-col gap-5">
            
            {/* Name (register only) */}
            {tab === 'register' && (
              <div className="relative">
                <div className="absolute inset-y-0 left-4 flex items-center pointer-events-none text-zinc-400">
                  <User size={18} />
                </div>
                <input
                  type="text"
                  placeholder="Full name"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  required
                  className="w-full bg-white border border-zinc-200 rounded-2xl py-4 pl-12 pr-4 text-zinc-800 text-[15px] placeholder:text-zinc-400 focus:outline-none focus:ring-2 focus:ring-[#53389e]/30 focus:border-[#53389e] transition-all shadow-sm"
                />
              </div>
            )}

            {/* Email */}
            <div className="relative">
              <div className="absolute inset-y-0 left-4 flex items-center pointer-events-none text-zinc-400">
                <Mail size={18} />
              </div>
              <input
                type="email"
                placeholder="Email address"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                className="w-full bg-white border border-zinc-200 rounded-2xl py-4 pl-12 pr-4 text-zinc-800 text-[15px] placeholder:text-zinc-400 focus:outline-none focus:ring-2 focus:ring-[#53389e]/30 focus:border-[#53389e] transition-all shadow-sm"
              />
            </div>

            {/* Password */}
            <div className="relative">
              <div className="absolute inset-y-0 left-4 flex items-center pointer-events-none text-zinc-400">
                <Lock size={18} />
              </div>
              <input
                type={showPass ? 'text' : 'password'}
                placeholder="Password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                className="w-full bg-white border border-zinc-200 rounded-2xl py-4 pl-12 pr-12 text-zinc-800 text-[15px] placeholder:text-zinc-400 focus:outline-none focus:ring-2 focus:ring-[#53389e]/30 focus:border-[#53389e] transition-all shadow-sm"
              />
              <button
                type="button"
                onClick={() => setShowPass(v => !v)}
                className="absolute inset-y-0 right-4 flex items-center text-zinc-400 hover:text-zinc-600 transition-colors"
              >
                {showPass ? <EyeOff size={18} /> : <Eye size={18} />}
              </button>
            </div>

            {/* Submit */}
            <button
              type="submit"
              disabled={loading}
              className="w-full py-4 mt-2 bg-[#53389e] hover:bg-[#432c81] text-white font-bold rounded-2xl shadow-lg shadow-purple-900/20 transition-all flex items-center justify-center gap-2 disabled:opacity-60 disabled:cursor-wait"
            >
              {loading ? 'Please wait...' : (tab === 'login' ? 'Sign In' : 'Create Account')}
              {!loading && <ArrowRight size={18} />}
            </button>

          </form>

          {/* Footer switch */}
          <p className="text-center text-zinc-500 text-sm mt-8">
            {tab === 'login' ? "Don't have an account? " : 'Already have an account? '}
            <button
              onClick={() => { setTab(tab === 'login' ? 'register' : 'login'); setError(''); setSuccess(''); }}
              className="text-[#53389e] font-bold hover:underline"
            >
              {tab === 'login' ? 'Register' : 'Sign In'}
            </button>
          </p>

        </div>
      </div>
    </div>
  );
}
