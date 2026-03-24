// State
let currentSponsors = [];
let currentBooks = [];

// Init
document.addEventListener('DOMContentLoaded', () => {
    if (!getToken()) {
        showLogin();
    } else {
        showDashboard();
    }

    // Event Listeners
    document.getElementById('login-form').addEventListener('submit', handleLogin);
    document.getElementById('rates-form').addEventListener('submit', handleUpdateRates);
    document.getElementById('add-sponsor-form').addEventListener('submit', handleAddSponsor);
    document.getElementById('edit-sponsor-form').addEventListener('submit', handleSaveSponsorEdit);
    document.getElementById('sponsor-book-form').addEventListener('submit', handleSponsorBook);
    document.getElementById('upload-book-form').addEventListener('submit', handleUploadBook);
    document.getElementById('edit-book-form').addEventListener('submit', handleSaveBookEdit);
    document.getElementById('create-promo-form').addEventListener('submit', handleCreateAd);
    document.getElementById('edit-promo-form').addEventListener('submit', handleSaveAdEdit);

    // Live Preview Listeners
    ['promo-section', 'promo-text', 'promo-link', 'promo-sticky'].forEach(id => {
        document.getElementById(id).addEventListener('change', updatePreview);
        document.getElementById(id).addEventListener('input', updatePreview);
    });
    ['promo-image', 'promo-logo'].forEach(id => {
        document.getElementById(id).addEventListener('change', updatePreview);
    });
    
    document.getElementById('promo-sponsor').addEventListener('change', (e) => {
        const selectedOption = e.target.options[e.target.selectedIndex];
        if (selectedOption && selectedOption.value !== "") {
            document.getElementById('promo-text').value = selectedOption.text;
            updatePreview();
        }
    });
});

// Navigation
function showLogin() {
    document.getElementById('login-section').classList.remove('hidden');
    document.getElementById('dashboard-section').classList.add('hidden');
}

function showDashboard() {
    document.getElementById('login-section').classList.add('hidden');
    document.getElementById('dashboard-section').classList.remove('hidden');
    
    // Default page
    showPage('books');
}

function showPage(pageId) {
    document.querySelectorAll('.page-section').forEach(el => el.classList.add('hidden'));
    document.getElementById(`page-${pageId}`).classList.remove('hidden');

    // Update active state in sidebar
    document.querySelectorAll('.nav-btn').forEach(el => {
        if (el.dataset.page === pageId) {
            el.classList.add('bg-[#EAE3D9]');
            el.classList.remove('hover:bg-[#F8F6F0]');
        } else {
            el.classList.remove('bg-[#EAE3D9]');
            el.classList.add('hover:bg-[#F8F6F0]');
        }
    });

    // Load Data
    if (pageId === 'books') loadBooks();
    if (pageId === 'sponsors') loadSponsors();
    if (pageId === 'ads') {
        loadAdSponsors();
        loadAds();
    }
}

function logout() {
    localStorage.removeItem('adminToken');
    showLogin();
}

async function loadAdSponsors() {
    const res = await apiFetch('/admin/sponsors');
    if (res.ok) {
        const sponsors = await res.json();
        const select = document.getElementById('promo-sponsor');
        select.innerHTML = '<option value="">Select Target Entity</option>' +
            sponsors.map(s => `<option value="${s.id}">${s.name}</option>`).join('');
    }
}

// Handlers
async function handleLogin(e) {
    e.preventDefault();
    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;

    const result = await loginAdmin(email, password);
    if (result.token) {
        setToken(result.token);
        showDashboard();
    } else {
        const errorEl = document.getElementById('login-error');
        errorEl.textContent = result.error || "Login Failed";
        errorEl.classList.remove('hidden');
    }
}

// --- BOOKS ---
async function loadBooks() {
    const res = await apiFetch('/admin/books');
    if (res.ok) {
        currentBooks = await res.json();
        renderBooks();
    }
}

function renderBooks() {
    const tbody = document.getElementById('books-list');
    tbody.innerHTML = currentBooks.map(book => `
        <tr class="hover:bg-[#FDFCFB] transition-colors group">
            <td class="py-4 px-6">
                <div class="font-medium text-[#3B2F2F]">${book.title}</div>
            </td>
            <td class="py-4 px-6 text-[#6B5A4E]">${book.author}</td>
            <td class="py-4 px-6 text-[#6B5A4E]">
                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-[#EAE3D9] text-[#4A3B32]">
                    ${book.sponsor_count || 0} sponsors
                </span>
                <span class="ml-2">${book.total_sponsored_amount || 0} Birr</span>
            </td>
            <td class="py-4 px-6 text-center">
                <span class="font-semibold text-[#8C7362]">${book.available_copies}</span> <span class="text-[#A4968C] text-xs">/ ${book.total_copies}</span>
            </td>
            <td class="py-4 px-6 text-right space-x-3 opacity-0 group-hover:opacity-100 transition-opacity">
                <button onclick="openSponsorModal(${book.id}, '${book.title.replace(/'/g,"\\'")}')" class="text-xs font-medium text-[#4A3B32] hover:text-[#8C7362] bg-[#F8F6F0] px-3 py-1.5 rounded-md border border-[#EAE3D9]">Fund</button>
                <button onclick="openEditBookModal(${book.id})" class="text-xs font-medium text-blue-600 hover:text-blue-800 bg-blue-50 px-3 py-1.5 rounded-md border border-blue-100">Edit</button>
                <button onclick="deleteBook(${book.id})" class="text-xs font-medium text-[#D35D5D] hover:text-red-800 bg-red-50 px-3 py-1.5 rounded-md border border-red-100">Drop</button>
            </td>
        </tr>
    `).join('');
}

async function handleUploadBook(e) {
    e.preventDefault();
    const formData = new FormData(e.target);
    const res = await apiFetch('/books/upload', {
        method: 'POST',
        body: formData
    });
    if (res.ok) {
        closeModal('upload-book-modal');
        loadBooks();
        e.target.reset();
    } else {
        alert('Upload failed');
    }
}

function openEditBookModal(id) {
    const book = currentBooks.find(b => b.id === id);
    if (!book) return;
    document.getElementById('edit-book-id').value = book.id;
    document.getElementById('edit-book-title').value = book.title;
    document.getElementById('edit-book-author').value = book.author;
    document.getElementById('edit-book-desc').value = book.description || "";
    document.getElementById('edit-book-avail').value = book.available_copies;
    document.getElementById('edit-book-total').value = book.total_copies;
    openModal('edit-book-modal');
}

async function handleSaveBookEdit(e) {
    e.preventDefault();
    const id = document.getElementById('edit-book-id').value;
    const formData = new FormData(e.target);

    const res = await apiFetch(`/admin/books/${id}`, {
        method: 'PUT',
        body: formData
    });
    if (res.ok) {
        closeModal('edit-book-modal');
        loadBooks();
    } else {
        alert('Failed to modify book details.');
    }
}

async function deleteBook(id) {
    if (!confirm('Warning: Deleting a book drops all associated records. Proceed?')) return;
    await apiFetch(`/admin/books/${id}`, { method: 'DELETE' });
    loadBooks();
}

// --- MODALS ---
function openModal(id) { 
    document.getElementById(id).classList.remove('hidden'); 
    setTimeout(() => {
        document.getElementById(id).children[0].classList.add('scale-100', 'opacity-100');
        document.getElementById(id).children[0].classList.remove('scale-95', 'opacity-0');
    }, 10);
}

function closeModal(id) { 
    document.getElementById(id).children[0].classList.remove('scale-100', 'opacity-100');
    document.getElementById(id).children[0].classList.add('scale-95', 'opacity-0');
    setTimeout(() => {
        document.getElementById(id).classList.add('hidden'); 
    }, 200);
}

// Apply transition classes initially
document.querySelectorAll('.modal-glass').forEach(el => {
    el.classList.add('transition-all', 'duration-200', 'transform', 'scale-95', 'opacity-0');
});

async function openSponsorModal(bookId, title) {
    document.getElementById('sponsor-book-id').value = bookId;
    document.getElementById('sponsor-book-title').textContent = title;

    const res = await apiFetch('/admin/sponsors');
    const sponsors = await res.json();
    const select = document.getElementById('sponsor-select');
    select.innerHTML = sponsors.map(s => `<option value="${s.id}">${s.name}</option>`).join('');

    openModal('sponsor-book-modal');
}

async function handleSponsorBook(e) {
    e.preventDefault();
    const bookId = document.getElementById('sponsor-book-id').value;
    const sponsorId = document.getElementById('sponsor-select').value;
    const amount = document.getElementById('sponsor-amount').value;

    const res = await apiFetch('/admin/books/sponsor', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ bookId, sponsorId, amount })
    });

    if (res.ok) {
        closeModal('sponsor-book-modal');
        loadBooks();
    } else {
        alert('Transaction failed to clear.');
    }
}

// --- SPONSORS ---
async function loadSponsors() {
    const res = await apiFetch('/admin/sponsors');
    if (res.ok) {
        currentSponsors = await res.json();
        renderSponsors();
    }

    const settingsRes = await apiFetch('/admin/settings');
    if (settingsRes.ok) {
        const settings = await settingsRes.json();
        document.getElementById('setting-amount').value = settings['sponsorship_rate_amount'] || 1000;
        document.getElementById('setting-copies').value = settings['sponsorship_rate_copies'] || 10;
        updateSponsorInfo();
    }
}

function updateSponsorInfo() {
    const amt = document.getElementById('setting-amount').value || 1000;
    const cps = document.getElementById('setting-copies').value || 10;
    document.getElementById('sponsor-calc-info').textContent = `System converts ${amt} Birr -> ${cps} inventory items globally.`;
}

function renderSponsors() {
    const list = document.getElementById('sponsors-list');
    list.innerHTML = currentSponsors.map(s => `
        <li class="px-8 py-5 hover:bg-[#FDFCFB] flex justify-between items-center group transition-colors">
            <div>
                <div class="font-semibold text-[#3B2F2F]">${s.name}</div>
                <div class="text-sm text-[#8D7B68] mt-1">${s.contact_info || 'No contact provided'}</div>
                <div class="text-xs text-[#A4968C] mt-2 border border-[#EAE3D9] inline-block px-2 py-0.5 rounded shadow-sm bg-white">Onboarded: ${new Date(s.created_at).toLocaleDateString()}</div>
            </div>
            <div class="opacity-0 group-hover:opacity-100 transition-opacity flex gap-2">
                <button onclick="openEditSponsor(${s.id})" class="text-xs font-medium text-blue-600 hover:text-blue-800 bg-blue-50 px-3 py-1.5 rounded-md border border-blue-100">Edit</button>
                <button onclick="deleteSponsor(${s.id})" class="text-xs font-medium text-[#D35D5D] hover:text-red-800 bg-red-50 px-3 py-1.5 rounded-md border border-red-100">Terminate</button>
            </div>
        </li>
    `).join('');
}

function openEditSponsor(id) {
    const s = currentSponsors.find(x => x.id === id);
    if (!s) return;
    document.getElementById('edit-sponsor-id').value = s.id;
    document.getElementById('edit-sponsor-name').value = s.name;
    document.getElementById('edit-sponsor-contact').value = s.contact_info || "";
    openModal('edit-sponsor-modal');
}

async function handleSaveSponsorEdit(e) {
    e.preventDefault();
    const id = document.getElementById('edit-sponsor-id').value;
    const name = document.getElementById('edit-sponsor-name').value;
    const contact_info = document.getElementById('edit-sponsor-contact').value;

    const res = await apiFetch(`/admin/sponsors/${id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, contact_info })
    });

    if (res.ok) {
        closeModal('edit-sponsor-modal');
        loadSponsors();
    } else {
        alert("Failed to update organization.");
    }
}

async function deleteSponsor(id) {
    if (!confirm('This action irrecoverably purges the sponsor data. Continue?')) return;
    const res = await apiFetch(`/admin/sponsors/${id}`, { method: 'DELETE' });
    if(res.ok) {
        loadSponsors();
    } else {
        alert("Delete blocked. They may have active ledgers linked to books.");
    }
}

async function handleUpdateRates(e) {
    e.preventDefault();
    const settings = {
        'sponsorship_rate_amount': document.getElementById('setting-amount').value,
        'sponsorship_rate_copies': document.getElementById('setting-copies').value
    };
    await apiFetch('/admin/settings', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ settings })
    });
    alert('System rates synchronized across all nodes.');
    updateSponsorInfo();
}

async function handleAddSponsor(e) {
    e.preventDefault();
    const name = document.getElementById('sponsor-name').value;
    const contact = document.getElementById('sponsor-contact').value;

    const res = await apiFetch('/admin/sponsors', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, contact_info: contact })
    });

    if (res.ok) {
        e.target.reset();
        loadSponsors();
    }
}

// --- ADS & PREVIEW ---
function updatePreview() {
    const section = document.getElementById('promo-section').value;
    const text = document.getElementById('promo-text').value;
    const link = document.getElementById('promo-link').value;
    const sticky = document.getElementById('promo-sticky').checked;

    const imageInput = document.getElementById('promo-image');
    const logoInput = document.getElementById('promo-logo');
    
    // Toggle field visibility based on section
    const fieldImage = document.getElementById('field-image');
    const fieldLogo = document.getElementById('field-logo');
    if (fieldImage && fieldLogo) {
        fieldImage.classList.remove('hidden');
        fieldLogo.classList.remove('hidden');
    }

    const previewContainer = document.getElementById('preview-container');
    previewContainer.className = "border border-[#EAE3D9] shadow-inner rounded-xl h-[450px] overflow-hidden bg-[#F8F6F0] relative items-center justify-center flex";

    const readFile = (input) => {
        if (input.files && input.files[0]) return URL.createObjectURL(input.files[0]);
        return null;
    };
    const imgUrl = readFile(imageInput) || 'https://via.placeholder.com/300x150?text=Primary+Creative';
    const logoUrl = readFile(logoInput) || 'https://via.placeholder.com/50?text=Logo';

    if (section === 'A') {
        previewContainer.innerHTML = `
            <div class="w-full max-w-sm bg-[#FDFCFB] shadow-lg h-full flex flex-col border border-[#EAE3D9]">
                <div class="bg-[#4A3B32] text-white p-2 text-xs font-medium tracking-wide">HOME VIEW CONTEXT</div>
                <div class="p-5 flex-1 space-y-4">
                     <div class="text-sm font-bold text-[#3B2F2F] tracking-wide uppercase mt-2">Library Spotlight</div>
                     <div class="relative w-full h-44 bg-[#EAE3D9] rounded-xl overflow-hidden shadow-sm">
                        <img src="${imgUrl}" class="w-full h-full object-cover">
                        <div class="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/80 to-transparent p-4 pb-3">
                            <span class="text-white font-medium text-sm drop-shadow line-clamp-2 leading-tight">${text || 'Inspiring copy goes here'}</span>
                        </div>
                     </div>
                </div>
            </div>
        `;
    } else if (section === 'B') {
        previewContainer.innerHTML = `
            <div class="w-full max-w-sm bg-white shadow-xl h-full flex flex-col relative border border-[#EAE3D9]">
                <div class="bg-[#4A3B32] text-white p-2 text-xs font-medium tracking-wide">READER VIEW CONTEXT</div>
                <div class="p-8 text-justify text-[#A4968C] text-xs overflow-hidden flex-1 font-serif leading-relaxed">
                    [Literature Content Simulation] "The quick brown fox jumps over the lazy dog."
                </div>
                <div class="${sticky ? 'absolute bottom-0' : 'relative'} w-full bg-[#fdfcfb] border-t border-[#EAE3D9] p-3 flex items-center gap-3">
                    <img src="${logoUrl}" class="w-10 h-10 rounded-md bg-[#EAE3D9] object-cover shadow-sm">
                    <div class="flex-1">
                        <div class="text-xs font-bold text-[#3B2F2F] leading-tight">${text || 'Marketing Copy'}</div>
                        <div class="text-[10px] text-[#A4968C] truncate mt-0.5">${link || 'Click path destination'}</div>
                    </div>
                </div>
            </div>
        `;
    } else if (section === 'C') {
        previewContainer.innerHTML = `
            <div class="w-full max-w-sm bg-[#3B2F2F] h-full relative flex flex-col overflow-hidden border border-black/20 shadow-xl">
                <img src="${imgUrl}" class="w-full h-full object-cover opacity-60">
                <div class="absolute inset-0 flex flex-col items-center justify-center text-white p-8 text-center bg-gradient-to-t from-black/90 via-black/40 to-black/20">
                    <img src="${logoUrl}" class="w-16 h-16 rounded-xl mb-4 bg-white/10 p-1 backdrop-blur shadow-lg border border-white/20">
                    <h2 class="text-2xl font-bold mb-2 tracking-tight">${text || 'Launch Narrative'}</h2>
                    <button class="bg-white text-[#3B2F2F] px-6 py-2.5 rounded-lg mt-4 font-semibold shadow-xl">Engage Now</button>
                    <button class="absolute top-4 right-4 text-white/70 bg-black/30 backdrop-blur border border-white/20 px-3 py-1.5 rounded-lg text-xs font-medium">Skip Narrative</button>
                </div>
            </div>
        `;
    }
}

async function handleCreateAd(e) {
    e.preventDefault();
    const formData = new FormData(e.target);
    const sponsorId = document.getElementById('promo-sponsor').value;
    formData.append('sponsor_id', sponsorId);

    const res = await apiFetch('/admin/promos', {
        method: 'POST',
        body: formData
    });
    if (res.ok) {
        alert('Campaign successfully broadcasted to live instances.');
        e.target.reset();
        loadAds();
        updatePreview();
    } else {
        alert('Transmission failed. Validate asset restrictions.');
    }
}

let currentAds = [];

async function loadAds() {
    const res = await apiFetch('/admin/promos');
    if (res.ok) {
        currentAds = await res.json();
        renderAds();
    }
}

function renderAds() {
    const tbody = document.getElementById('ads-list');
    tbody.innerHTML = currentAds.map(ad => `
        <tr class="hover:bg-[#FDFCFB] transition-colors group ${ad.is_active ? '' : 'opacity-60'}">
            <td class="py-4 px-6">
                <div class="flex items-center gap-3">
                    ${ad.logo_path ? `<img src="${ad.logo_path.startsWith('http') ? ad.logo_path : '/api' + ad.logo_path}" class="w-8 h-8 rounded-md object-cover bg-gray-100">` : '<div class="w-8 h-8 rounded-md bg-gray-200"></div>'}
                    <div class="font-medium text-[#3B2F2F] whitespace-nowrap">${ad.sponsor_name || 'Unknown Entity'}</div>
                </div>
            </td>
            <td class="py-4 px-6 text-[#6B5A4E]">
                <span class="inline-flex items-center px-2 py-1 rounded text-xs font-semibold bg-gray-100 text-gray-700">
                    Slot ${ad.section}
                </span>
            </td>
            <td class="py-4 px-6 text-[#6B5A4E] text-xs max-w-[200px] truncate">
                ${ad.u_text || '-'}
            </td>
            <td class="py-4 px-6 text-center">
                ${ad.is_active 
                    ? '<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">Active</span>'
                    : '<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">Inactive</span>'
                }
            </td>
            <td class="py-4 px-6 text-right space-x-2 opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap">
                <button onclick="toggleAd(${ad.id})" class="text-xs font-medium text-gray-600 hover:text-gray-900 bg-gray-50 px-3 py-1.5 rounded-md border border-gray-200">${ad.is_active ? 'Disable' : 'Enable'}</button>
                <button onclick="openEditAdModal(${ad.id})" class="text-xs font-medium text-blue-600 hover:text-blue-800 bg-blue-50 px-3 py-1.5 rounded-md border border-blue-100">Edit</button>
                <button onclick="deleteAd(${ad.id})" class="text-xs font-medium text-[#D35D5D] hover:text-red-800 bg-red-50 px-3 py-1.5 rounded-md border border-red-100">Terminate</button>
            </td>
        </tr>
    `).join('');
}

async function toggleAd(id) {
    const res = await apiFetch(`/admin/promos/${id}/toggle`, { method: 'POST' });
    if (res.ok) loadAds();
}

async function deleteAd(id) {
    if (!confirm('Warning: Permanently delete this campaign block?')) return;
    const res = await apiFetch(`/admin/promos/${id}`, { method: 'DELETE' });
    if (res.ok) loadAds();
}

function openEditAdModal(id) {
    const ad = currentAds.find(a => a.id === id);
    if (!ad) return;
    document.getElementById('edit-promo-id').value = ad.id;
    document.getElementById('edit-promo-text').value = ad.u_text || '';
    document.getElementById('edit-promo-link').value = ad.redirect_link || '';
    document.getElementById('edit-promo-section').value = ad.section || 'A';
    document.getElementById('edit-promo-sticky').checked = ad.is_sticky == 1;
    openModal('edit-promo-modal');
}

async function handleSaveAdEdit(e) {
    e.preventDefault();
    const id = document.getElementById('edit-promo-id').value;
    const formData = new FormData(e.target);
    
    // Checkboxes only send value if checked. If not checked, manually append false.
    if (!document.getElementById('edit-promo-sticky').checked) {
        formData.append('is_sticky', 'false');
    }

    const res = await apiFetch(`/admin/promos/${id}`, {
        method: 'PUT',
        body: formData
    });
    if (res.ok) {
        closeModal('edit-promo-modal');
        loadAds();
    } else {
        alert('Failed to modify campaign.');
    }
}

