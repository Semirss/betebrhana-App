import CryptoJS from 'crypto-js';

// Get or generate a 32-byte key
function getOrCreateKey() {
  let storedKey = localStorage.getItem('device_encryption_key_v1');
  if (!storedKey) {
    // Generate 32 bytes
    const randomArray = new Uint8Array(32);
    crypto.getRandomValues(randomArray);
    const keyWordArray = CryptoJS.lib.WordArray.create(randomArray);
    storedKey = CryptoJS.enc.Base64.stringify(keyWordArray);
    localStorage.setItem('device_encryption_key_v1', storedKey);
  }
  return CryptoJS.enc.Base64.parse(storedKey);
}

/**
 * ArrayBuffer to WordArray
 */
function arrayBufferToWordArray(ab) {
  const i8a = new Uint8Array(ab);
  const a = [];
  for (let i = 0; i < i8a.length; i += 4) {
    a.push((i8a[i] << 24) | (i8a[i + 1] << 16) | (i8a[i + 2] << 8) | i8a[i + 3]);
  }
  return CryptoJS.lib.WordArray.create(a, i8a.length);
}

/**
 * WordArray to ArrayBuffer
 */
function wordArrayToArrayBuffer(wordArray) {
  const words = wordArray.words;
  const sigBytes = wordArray.sigBytes;
  const u8 = new Uint8Array(sigBytes);
  for (let i = 0; i < sigBytes; i++) {
    const byte = (words[i >>> 2] >>> (24 - (i % 4) * 8)) & 0xff;
    u8[i] = byte;
  }
  return u8.buffer;
}

export function encryptBytes(arrayBuffer) {
  const key = getOrCreateKey();
  
  // 16 bytes IV
  const ivArray = new Uint8Array(16);
  crypto.getRandomValues(ivArray);
  const iv = CryptoJS.lib.WordArray.create(ivArray);
  
  const plainText = arrayBufferToWordArray(arrayBuffer);
  
  const encrypted = CryptoJS.AES.encrypt(plainText, key, {
    iv: iv,
    mode: CryptoJS.mode.CBC,
    padding: CryptoJS.pad.Pkcs7
  });
  
  // Combine IV + Ciphertext
  const cipherBytes = wordArrayToArrayBuffer(encrypted.ciphertext);
  
  const result = new Uint8Array(16 + cipherBytes.byteLength);
  result.set(ivArray, 0);
  result.set(new Uint8Array(cipherBytes), 16);
  
  return result.buffer;
}

export function decryptBytes(arrayBuffer) {
  const key = getOrCreateKey();
  const dataView = new Uint8Array(arrayBuffer);
  
  if (dataView.length < 16) {
    throw new Error('Encrypted data is too short');
  }
  
  const ivArray = dataView.slice(0, 16);
  const cipherArray = dataView.slice(16);
  
  const iv = CryptoJS.lib.WordArray.create(ivArray);
  const cipherTextWordArray = CryptoJS.lib.WordArray.create(cipherArray);
  
  const decrypted = CryptoJS.AES.decrypt({ ciphertext: cipherTextWordArray }, key, {
    iv: iv,
    mode: CryptoJS.mode.CBC,
    padding: CryptoJS.pad.Pkcs7
  });
  
  return wordArrayToArrayBuffer(decrypted);
}
