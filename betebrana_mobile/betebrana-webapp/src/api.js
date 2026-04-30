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

// Handle Auth errors globally (401 = unauthorized, 403 = session expired/forbidden)
// We fire a custom event so that AuthContext can react and clear React state properly,
// rather than just wiping localStorage while the UI stays logged-in.
api.interceptors.response.use(
  (response) => response,
  (error) => {
    const status = error.response?.status;
    if (status === 401 || status === 403) {
      // Dispatch a custom event; AuthContext listens for this and calls logout()
      window.dispatchEvent(new Event('auth:expired'));
    }
    return Promise.reject(error);
  }
);

export default api;
