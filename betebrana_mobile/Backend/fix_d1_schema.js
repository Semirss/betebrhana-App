require('dotenv').config();
const axios = require('axios');

async function executeD1(query) {
    const accountId = process.env.CF_ACCOUNT_ID;
    const dbId = process.env.CF_D1_DATABASE_ID;
    const token = process.env.CF_API_TOKEN;

    const url = `https://api.cloudflare.com/client/v4/accounts/${accountId}/d1/database/${dbId}/query`;
    
    try {
        const response = await axios.post(url, {
          sql: query
        }, {
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
          }
        });
        return response.data;
    } catch(e) {
        console.error("D1 API Error:", JSON.stringify(e.response ? e.response.data : e.message, null, 2));
        throw e;
    }
}

async function fixTable(tableName, newCreateSql) {
    console.log(`Fixing table ${tableName}...`);
    try {
        // 1. Create new table
        await executeD1(newCreateSql);
        
        // 2. Copy data
        await executeD1(`INSERT INTO ${tableName}_new SELECT * FROM ${tableName};`);
        
        // 3. Drop old table
        await executeD1(`DROP TABLE ${tableName};`);
        
        // 4. Rename new table
        await executeD1(`ALTER TABLE ${tableName}_new RENAME TO ${tableName};`);
        
        console.log(`  Done with ${tableName}!\n`);
    } catch (e) {
        console.error(`  Failed on ${tableName}`);
    }
}

async function run() {
    await executeD1("DROP TABLE IF EXISTS users_new;");
    await fixTable("users", `CREATE TABLE users_new (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email varchar(255) NOT NULL,
  password varchar(255) NOT NULL,
  name varchar(255) NOT NULL,
  created_at timestamp NULL DEFAULT CURRENT_TIMESTAMP
)`);

    await executeD1("DROP TABLE IF EXISTS admin_users_new;");
    await fixTable("admin_users", `CREATE TABLE admin_users_new (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email varchar(255) NOT NULL,
  password varchar(255) NOT NULL,
  name varchar(255) NOT NULL,
  created_at timestamp NULL DEFAULT CURRENT_TIMESTAMP
)`);

    await executeD1("DROP TABLE IF EXISTS advertisements_new;");
    await fixTable("advertisements", `CREATE TABLE advertisements_new (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  section TEXT NOT NULL,
  image_path varchar(500) DEFAULT NULL,
  logo_path varchar(500) DEFAULT NULL,
  u_text varchar(255) DEFAULT NULL,
  redirect_link varchar(500) DEFAULT NULL,
  is_active INTEGER DEFAULT 1,
  created_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  sponsor_id INTEGER DEFAULT NULL,
  is_sticky INTEGER DEFAULT 0
)`);

    await executeD1("DROP TABLE IF EXISTS books_new;");
    await fixTable("books", `CREATE TABLE books_new (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title varchar(255) NOT NULL,
  author varchar(255) NOT NULL,
  description text DEFAULT NULL,
  total_copies INTEGER DEFAULT 1,
  available_copies INTEGER DEFAULT 1,
  file_path varchar(500) DEFAULT NULL,
  file_type TEXT DEFAULT NULL,
  file_size INTEGER DEFAULT NULL,
  cover_image varchar(500) DEFAULT NULL,
  created_at timestamp NULL DEFAULT CURRENT_TIMESTAMP
)`);

    await executeD1("DROP TABLE IF EXISTS book_sponsors_new;");
    await fixTable("book_sponsors", `CREATE TABLE book_sponsors_new (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  book_id INTEGER NOT NULL,
  sponsor_id INTEGER NOT NULL,
  amount_paid decimal(10,2) NOT NULL,
  copies_added INTEGER NOT NULL,
  created_at timestamp NULL DEFAULT CURRENT_TIMESTAMP
)`);

    await executeD1("DROP TABLE IF EXISTS offline_access_new;");
    await fixTable("offline_access", `CREATE TABLE offline_access_new (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  book_id INTEGER NOT NULL,
  device_fingerprint varchar(255) NOT NULL,
  device_type TEXT NOT NULL DEFAULT 'desktop',
  expires_at datetime NOT NULL,
  created_at datetime DEFAULT CURRENT_TIMESTAMP,
  last_verified datetime DEFAULT NULL,
  is_active INTEGER DEFAULT 1
)`);

    await executeD1("DROP TABLE IF EXISTS queue_new;");
    await fixTable("queue", `CREATE TABLE queue_new (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  book_id INTEGER DEFAULT NULL,
  user_id INTEGER DEFAULT NULL,
  added_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  available_at timestamp NULL DEFAULT NULL,
  expires_at timestamp NULL DEFAULT NULL,
  status TEXT DEFAULT 'waiting'
)`);

    await executeD1("DROP TABLE IF EXISTS reading_progress_new;");
    await fixTable("reading_progress", `CREATE TABLE reading_progress_new (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER DEFAULT NULL,
  book_id INTEGER DEFAULT NULL,
  progress float DEFAULT 0,
  last_page INTEGER DEFAULT 1,
  last_read timestamp NULL DEFAULT CURRENT_TIMESTAMP
)`);

    await executeD1("DROP TABLE IF EXISTS rentals_new;");
    await fixTable("rentals", `CREATE TABLE rentals_new (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  book_id INTEGER DEFAULT NULL,
  user_id INTEGER DEFAULT NULL,
  rented_at timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  due_date timestamp NULL DEFAULT NULL,
  returned_at timestamp NULL DEFAULT NULL,
  status TEXT DEFAULT 'active'
)`);

    await executeD1("DROP TABLE IF EXISTS sponsors_new;");
    await fixTable("sponsors", `CREATE TABLE sponsors_new (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name varchar(255) NOT NULL,
  contact_info text DEFAULT NULL,
  created_at timestamp NULL DEFAULT CURRENT_TIMESTAMP
)`);

    await executeD1("DROP TABLE IF EXISTS user_devices_new;");
    await fixTable("user_devices", `CREATE TABLE user_devices_new (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  device_fingerprint varchar(255) NOT NULL,
  device_type TEXT NOT NULL,
  device_name varchar(255) DEFAULT NULL,
  last_used datetime DEFAULT CURRENT_TIMESTAMP,
  created_at datetime DEFAULT CURRENT_TIMESTAMP,
  is_active INTEGER DEFAULT 1
)`);
}

run();
