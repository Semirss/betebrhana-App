import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import { useAuth } from '../context/AuthContext';

export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();
  const { login } = useAuth(); // Global AuthContext

  const handleLogin = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const res = await axios.post('https://betebrhana-app.onrender.com/api/auth/login', {
        email, password
      });
      
      const { token, user } = res.data;
      if (token) {
        login(user, token); // Stores it locally and in state
        navigate('/');
      } else {
        setError('Login failed, no token received.');
      }
    } catch (err) {
      setError(err.response?.data?.message || err.response?.data?.error || 'Invalid credentials. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex flex-col justify-center px-8 relative">
      <div className="mb-12">
        <h1 className="text-4xl font-serif font-bold text-primary mb-2">BeteBrana</h1>
        <p className="text-zinc-500">Welcome back! Please login to continue.</p>
      </div>

      <form onSubmit={handleLogin} className="flex flex-col gap-6 relative z-10">
        {error && <div className="p-4 bg-red-100/80 backdrop-blur-md text-red-700 rounded-2xl text-sm border border-red-200">{error}</div>}
        
        <div className="flex flex-col gap-2">
          <label className="text-sm font-bold text-zinc-500 tracking-wider">EMAIL ADDRESS</label>
          <input 
            type="email" 
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="w-full bg-white/70 backdrop-blur-md border border-zinc-200/50 rounded-2xl py-4 px-4 focus:outline-none focus:ring-2 focus:ring-primary transition-all shadow-sm"
            required
            placeholder="you@example.com"
          />
        </div>

        <div className="flex flex-col gap-2">
          <label className="text-sm font-bold text-zinc-500 tracking-wider">PASSWORD</label>
          <input 
            type="password" 
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="w-full bg-white/70 backdrop-blur-md border border-zinc-200/50 rounded-2xl py-4 px-4 focus:outline-none focus:ring-2 focus:ring-primary transition-all shadow-sm"
            required
            placeholder="••••••••"
          />
        </div>

        <button 
          type="submit" 
          disabled={loading}
          className="w-full py-4 mt-6 bg-zinc-900 text-white font-bold tracking-widest uppercase rounded-2xl shadow-xl transition-all hover:-translate-y-1 hover:shadow-2xl disabled:opacity-50 disabled:hover:translate-y-0"
        >
          {loading ? 'Logging in...' : 'Log In'}
        </button>
      </form>
      
      {/* Decorative Blur Orbs */}
      <div className="absolute top-1/4 left-0 w-64 h-64 bg-primary/10 rounded-full blur-3xl -z-10 pointer-events-none"></div>
      <div className="absolute bottom-0 right-0 w-80 h-80 bg-blue-400/10 rounded-full blur-3xl -z-10 pointer-events-none"></div>
    </div>
  );
}
