import localforage from 'localforage';
import axios from 'axios';
import { encryptBytes, decryptBytes } from './encryption.js';

// Setup separated instances for cache and metadata
const booksDb = localforage.createInstance({
  name: 'BeteBranaDb',
  storeName: 'books_files'
});

const metaDb = localforage.createInstance({
  name: 'BeteBranaDb',
  storeName: 'books_meta'
});

export async function hasDownloadedBook(bookId) {
  const meta = await metaDb.getItem(bookId);
  return !!meta;
}

export async function downloadBook(bookId, bookMeta) {
  try {
    const token = localStorage.getItem('access_token');
    
    // We assume the backend exposes the download URL, similar to Flutter
    // You might need to adjust the exact endpoint to match the backend docs
    const response = await axios.get(`https://betebrhana-app.onrender.com/api/books/${bookId}/download`, {
      headers: {
        Authorization: `Bearer ${token}`
      },
      responseType: 'arraybuffer'
    });

    // We encrypt the received buffer
    const encryptedData = encryptBytes(response.data);
    
    // Default format inferred from response headers
    const contentType = response.headers['content-type'];
    const extension = contentType?.includes('pdf') ? 'pdf' : 'epub';

    const localMeta = {
      ...bookMeta,
      format: extension,
      downloadedAt: new Date().toISOString()
    };
    
    // Save metadata
    await metaDb.setItem(bookId, localMeta);
    // Save encrypted file
    await booksDb.setItem(bookId, encryptedData);

    return true;
  } catch (error) {
    console.error("Failed to download or encrypt the book:", error);
    throw error;
  }
}

export async function readBookFile(bookId) {
  const encryptedData = await booksDb.getItem(bookId);
  if (!encryptedData) {
    throw new Error('Book file not found offline');
  }
  
  // Decrypt to raw buffer
  const decryptedBuffer = decryptBytes(encryptedData);
  return decryptedBuffer;
}

export async function getDownloadedBooks() {
  const books = [];
  await metaDb.iterate((value, key) => {
    books.push(value);
  });
  return books;
}

export async function deleteBook(bookId) {
  await booksDb.removeItem(bookId);
  await metaDb.removeItem(bookId);
}
