const API_URL = "https://betebrhana-app.onrender.com/api";

function getToken() {
    return localStorage.getItem('adminToken');
}

function setToken(token) {
    localStorage.setItem('adminToken', token);
}

function logout() {
    localStorage.removeItem('adminToken');
    window.location.reload();
}

async function apiFetch(endpoint, options = {}) {
    const token = getToken();
    const headers = options.headers || {};

    if (token) {
        headers['Authorization'] = `Bearer ${token}`;
    }

    if (!(options.body instanceof FormData) && !headers['Content-Type']) {
        headers['Content-Type'] = 'application/json';
    }

    const response = await fetch(`${API_URL}${endpoint}`, {
        ...options,
        headers
    });

    if (response.status === 401 || response.status === 403) {
        // If unauthorized, maybe logout if it's strictly guarded
        // logout(); 
    }

    return response;
}

async function loginAdmin(email, password) {
    const res = await fetch(`${API_URL}/admin/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password })
    });
    return res.json();
}
