import axios from 'axios';

// Create an axios instance pointing to the backend
const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'https://betebrhana-app.onrender.com/api',
});

// Automatically attach JWT token to all requests
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('access_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Handle Auth errors globally (like 401s to force logout)
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Clear token and redirect to login contextually
      localStorage.removeItem('access_token');
      localStorage.removeItem('user');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export default api;
