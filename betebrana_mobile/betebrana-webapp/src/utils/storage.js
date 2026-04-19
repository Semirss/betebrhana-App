import localforage from 'localforage';
import api from '../api';
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
  const meta = await metaDb.getItem(bookId.toString());
  return !!meta;
}

export async function downloadBook(bookId, bookMeta) {
  try {
    // Note: server.js uses /api/books/:id/read to deliver the raw file stream
    const response = await api.get(`/books/${bookId}/read`, {
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
    await metaDb.setItem(bookId.toString(), localMeta);
    // Save encrypted file
    await booksDb.setItem(bookId.toString(), encryptedData);

    return true;
  } catch (error) {
    console.error("Failed to download or encrypt the book:", error);
    throw error;
  }
}

export async function readBookFile(bookId) {
  const encryptedData = await booksDb.getItem(bookId.toString());
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
  await booksDb.removeItem(bookId.toString());
  await metaDb.removeItem(bookId.toString());
}
