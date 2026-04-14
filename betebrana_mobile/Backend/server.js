require("dotenv").config();
const express = require("express");
const path = require("path");
const mysql = require("mysql2/promise");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const fs = require("fs");
const mammoth = require("mammoth");
const pdfParse = require("pdf-parse");
const multer = require("multer");
const axios = require("axios");
const app = express();
const PORT = process.env.PORT || 3000;
const cors = require("cors");
// CORS - allow all origins since this is a mobile-first API
app.use(
  cors({
    origin: true, // Reflect request origin; mobile apps have no "origin" anyway
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization", "X-Requested-With"],
    credentials: true,
    exposedHeaders: ["Content-Disposition"],
  })
);

// Middleware
app.use(express.json());
app.use("/documents", express.static("documents"));
app.use("/covers", express.static("covers"));

// ===== END CORS MIDDLEWARE =====

// GitHub Upload Helper
async function uploadToGitHub(fileBuffer, originalName, folderPath) {
  const token = process.env.GITHUB_TOKEN;
  const repoSlug = process.env.GITHUB_REPO;

  if (!token || !repoSlug) {
    throw new Error("GitHub credentials not configured in environment variables");
  }

  const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
  const fileName = uniqueSuffix + path.extname(originalName);
  const basePath = process.env.GITHUB_BASE_PATH || "";

  // Combine basePath, folderPath and fileName (e.g. "betebrana_mobile/Backend/documents/file.jpg")
  // Replace Windows backslashes with forward slashes for the GitHub API URL
  const filePath = basePath
    ? `${basePath}/${folderPath}/${fileName}`.replace(/\/+/g, '/')
    : `${folderPath}/${fileName}`;

  const contentEncoded = fileBuffer.toString("base64");
  const url = `https://api.github.com/repos/${repoSlug}/contents/${filePath}`;

  await axios.put(
    url,
    {
      message: `Upload ${fileName}`,
      content: contentEncoded,
      branch: "main",
    },
    {
      headers: {
        Authorization: `token ${token}`,
        "Content-Type": "application/json",
      },
    }
  );

  return `https://raw.githubusercontent.com/${repoSlug}/main/${filePath}`;
}

// File upload configuration - using Memory Storage for GitHub push
const storage = multer.memoryStorage();

const upload = multer({
  storage: storage,
  fileFilter: (req, file, cb) => {
    const allowedTypes = [".pdf", ".doc", ".docx", ".txt", ".jpg", ".jpeg", ".png", ".gif", ".webp"];
    const fileExt = path.extname(file.originalname).toLowerCase();
    if (allowedTypes.includes(fileExt)) {
      cb(null, true);
    } else {
      cb(new Error("Only PDF, Word, text, and image files are allowed"));
    }
  },
  limits: {
    fileSize: 50 * 1024 * 1024, // 50MB limit
  },
});

// MySQL connection pool
const pool = mysql.createPool({
  host: process.env.MYSQL_HOST || "localhost",
  user: process.env.MYSQL_USER || "root",
  password: process.env.MYSQL_PASSWORD || "",
  database: process.env.MYSQL_DATABASE || "betebrana",
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
});

// Initialize database
async function initializeDatabase() {
  try {
    const connection = await pool.getConnection();

    // Verify existing tables
    await connection.execute("SELECT 1 FROM users LIMIT 1");
    await connection.execute("SELECT 1 FROM books LIMIT 1");
    await connection.execute("SELECT 1 FROM rentals LIMIT 1");
    await connection.execute("SELECT 1 FROM queue LIMIT 1");

    console.log("Basic tables verified. Running Admin Schema updates...");

    // Read and execute admin_schema.sql
    try {
      const schemaPath = path.join(__dirname, 'admin_schema.sql');
      const schemaSql = fs.readFileSync(schemaPath, 'utf8');
      const statements = schemaSql.split(';').filter(stmt => stmt.trim());

      for (const statement of statements) {
        if (statement.trim()) {
          await connection.execute(statement);
        }
      }
      console.log("Admin schema applied successfully.");

      // Check/Seed Default Admin
      const [admins] = await connection.execute("SELECT * FROM admin_users WHERE email = ?", ['admin@betebrana.com']);
      if (admins.length === 0) {
        const hashedPassword = await bcrypt.hash('admin123', 10);
        await connection.execute(
          "INSERT INTO admin_users (email, password, name) VALUES (?, ?, ?)",
          ['admin@betebrana.com', hashedPassword, 'Super Admin']
        );
        console.log("Default admin user created: admin@betebrana.com / admin123");
      }

    } catch (schemaError) {
      console.error("Error applying admin schema:", schemaError);
    }

    connection.release();
    console.log("Database initialized successfully");
  } catch (error) {
    console.error(
      "Database verification failed - tables may not exist:",
      error
    );
    // Here you could choose to create tables or exit
    process.exit(1);
  }
}
// JWT middleware
function authenticateToken(req, res, next) {
  const authHeader = req.headers["authorization"];
  const token = authHeader && authHeader.split(" ")[1];

  if (!token) {
    return res.status(401).json({ error: "Access token required" });
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: "Invalid token" });
    }
    req.user = user;
    next();
  });
}

// Admin Middleware
function authenticateAdmin(req, res, next) {
  const authHeader = req.headers["authorization"];
  const token = authHeader && authHeader.split(" ")[1];

  if (!token) {
    return res.status(401).json({ error: "Admin token required" });
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: "Invalid token" });
    }
    // Check if user has admin privileges (you might want a separate secret or role check)
    // For now, we assume the token payload indicates role or we check DB if strictly separated
    // Since we maintain a separate admin_users table, we might issue tokens signed with 'role: admin'
    if (user.role !== 'admin') {
      return res.status(403).json({ error: "Admin access required" });
    }
    req.admin = user;
    next();
  });
}
// Function to process expired rentals (21-day rental period)
async function processExpiredRentals() {
  try {
    // Find rentals that are overdue (due_date has passed)
    // We pass the current localized Node Date to bypass timezone discrepancies
    const [expiredRentals] = await pool.execute(`
        SELECT r.*, b.title 
        FROM rentals r 
        JOIN books b ON r.book_id = b.id 
        WHERE r.status = 'active' 
        AND r.due_date < ?
        LIMIT 100
    `, [new Date()]);

    console.log(`Found ${expiredRentals.length} expired rentals to process`);

    let processedCount = 0;

    for (const rental of expiredRentals) {
      try {
        // Mark rental as expired (auto-returned)
        await pool.execute(
          'UPDATE rentals SET status = "expired", returned_at = NOW() WHERE id = ?',
          [rental.id]
        );

        // Update book availability
        await pool.execute(
          "UPDATE books SET available_copies = available_copies + 1 WHERE id = ?",
          [rental.book_id]
        );

        // Process queue for this book
        await processQueue(rental.book_id);

        console.log(
          `Auto-returned book "${rental.title}" for user ${rental.user_id}`
        );
        processedCount++;
      } catch (error) {
        console.error(`Error processing rental ${rental.id}:`, error);
      }
    }

    console.log(`Auto-returned ${processedCount} expired rentals`);
    return processedCount;
  } catch (error) {
    console.error("Process expired rentals error:", error);
    return 0;
  }
}

// Helper function to process queue when book is returned
// Update the processQueue function to handle the LIMIT parameter correctly
// Fix the processQueue function - remove parameter binding for LIMIT
async function processQueue(bookId) {
  try {
    const [books] = await pool.execute("SELECT * FROM books WHERE id = ?", [
      bookId,
    ]);
    if (books.length === 0) return;

    const book = books[0];

    if (book.available_copies > 0) {
      // Get waiting users in queue order - use template literal for LIMIT
      const [queueItems] = await pool.execute(
        `
          SELECT * FROM queue 
          WHERE book_id = ? AND status = 'waiting'
          ORDER BY added_at ASC 
          LIMIT ${book.available_copies}
      `,
        [bookId]
      );

      console.log(
        `Processing queue for book "${book.title}": ${queueItems.length} users can be moved to available status`
      );

      // Mark these users as having the book available
      const now = new Date();
      const expiryDate = new Date(now.getTime() + 2 * 24 * 60 * 60 * 1000); // 2 days from now

      for (const queueItem of queueItems) {
        await pool.execute(
          'UPDATE queue SET status = "available", available_at = ?, expires_at = ? WHERE id = ?',
          [now, expiryDate, queueItem.id]
        );

        console.log(
          `Book "${book.title}" is now available for user ${queueItem.user_id}. Reservation expires at ${expiryDate}`
        );
      }
    }
  } catch (error) {
    console.error("Process queue error:", error);
  }
}
// Clean up expired queue entries (call this periodically)
async function cleanupExpiredQueue() {
  try {
    let totalCleaned = 0;

    // 1. Delete queue entries where reservation has expired (2-day waiting time)
    const [expiredReservations] = await pool.execute(`
        DELETE FROM queue 
        WHERE status = 'available' 
        AND expires_at < NOW()
    `);

    const expiredReservationCount = expiredReservations.affectedRows;
    totalCleaned += expiredReservationCount;

    console.log(`Cleaned up ${expiredReservationCount} expired reservations`);

    // 2. Also remove users who have been waiting too long (2 days total wait time)
    const [expiredWaiting] = await pool.execute(`
        DELETE FROM queue 
        WHERE status = 'waiting' 
        AND added_at < DATE_SUB(NOW(), INTERVAL 2 DAY)
    `);

    const expiredWaitingCount = expiredWaiting.affectedRows;
    totalCleaned += expiredWaitingCount;

    if (expiredWaitingCount > 0) {
      console.log(
        `Removed ${expiredWaitingCount} users who waited too long (2+ days)`
      );
    }

    // Process queue for books that now have available copies
    if (totalCleaned > 0) {
      // Get books that had expired reservations or removed waiting users
      const [affectedBooks] = await pool.execute(`
          SELECT DISTINCT book_id FROM queue 
          WHERE status = 'available' 
          AND expires_at < NOW()
          UNION
          SELECT DISTINCT book_id FROM queue 
          WHERE status = 'waiting' 
          AND added_at < DATE_SUB(NOW(), INTERVAL 2 DAY)
      `);

      // Process queue for each affected book
      for (const book of affectedBooks) {
        await processQueue(book.book_id);
      }
    }

    return totalCleaned;
  } catch (error) {
    console.error("Queue cleanup error:", error);
    return 0;
  }
}
// Routes
app.get("/", (req, res) => {
  res.json({
    status: "ok",
    message: "BeteBrana API server is running 🚀",
    version: "1.0.0",
  });
});

// Test endpoint
app.get("/api/test", async (req, res) => {
  try {
    const [rows] = await pool.execute("SELECT 1 as test");
    res.json({
      success: true,
      message: "Database connection successful",
      data: rows,
    });
  } catch (error) {
    res
      .status(500)
      .json({
        success: false,
        message: "Database connection failed",
        error: error.message,
      });
  }
});

// Authentication endpoints
app.post("/api/auth/register", async (req, res) => {
  const { email, password, name } = req.body;

  if (!email || !password || !name) {
    return res
      .status(400)
      .json({ error: "Email, password, and name are required" });
  }

  try {
    const [existingUsers] = await pool.execute(
      "SELECT id FROM users WHERE email = ?",
      [email]
    );
    if (existingUsers.length > 0) {
      return res.status(400).json({ error: "User already exists" });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const [result] = await pool.execute(
      "INSERT INTO users (email, password, name) VALUES (?, ?, ?)",
      [email, hashedPassword, name]
    );

    const token = jwt.sign(
      { id: result.insertId, email, name },
      process.env.JWT_SECRET,
      { expiresIn: "24h" }
    );

    res.json({
      user: { id: result.insertId, email, name },
      token,
      message: "Registration successful",
    });
  } catch (error) {
    console.error("Registration error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

app.post("/api/auth/login", async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: "Email and password are required" });
  }

  try {
    const [users] = await pool.execute("SELECT * FROM users WHERE email = ?", [
      email,
    ]);
    if (users.length === 0) {
      return res.status(400).json({ error: "Invalid credentials" });
    }

    const user = users[0];
    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) {
      return res.status(400).json({ error: "Invalid credentials" });
    }

    const token = jwt.sign(
      { id: user.id, email: user.email, name: user.name },
      process.env.JWT_SECRET,
      { expiresIn: "24h" }
    );

    res.json({
      user: { id: user.id, email: user.email, name: user.name },
      token,
      message: "Login successful",
    });
  } catch (error) {
    console.error("Login error:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Admin Authentication
app.post("/api/admin/auth/login", async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: "Email and password are required" });
  }

  try {
    const [admins] = await pool.execute("SELECT * FROM admin_users WHERE email = ?", [email]);
    if (admins.length === 0) {
      return res.status(400).json({ error: "Invalid admin credentials" });
    }

    const admin = admins[0];
    const validPassword = await bcrypt.compare(password, admin.password);
    if (!validPassword) {
      return res.status(400).json({ error: "Invalid admin credentials" });
    }

    const token = jwt.sign(
      { id: admin.id, email: admin.email, name: admin.name, role: 'admin' },
      process.env.JWT_SECRET,
      { expiresIn: "12h" }
    );

    res.json({
      admin: { id: admin.id, email: admin.email, name: admin.name },
      token,
      message: "Admin login successful"
    });

  } catch (error) {
    console.error("Admin Login Error:", error);
    res.status(500).json({ error: "Internal Server Error" });
  }
});

// ==========================================
// ADMIN ENDPOINTS
// ==========================================

// --- Sponsor Management ---
app.get("/api/admin/sponsors", authenticateAdmin, async (req, res) => {
  try {
    const [sponsors] = await pool.execute("SELECT * FROM sponsors ORDER BY created_at DESC");
    res.json(sponsors);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

app.post("/api/admin/sponsors", authenticateAdmin, async (req, res) => {
  const { name, contact_info } = req.body;
  if (!name) return res.status(400).json({ error: "Name required" });
  try {
    const [result] = await pool.execute("INSERT INTO sponsors (name, contact_info) VALUES (?, ?)", [name, contact_info]);
    res.json({ success: true, id: result.insertId });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

app.put("/api/admin/sponsors/:id", authenticateAdmin, async (req, res) => {
  const { name, contact_info } = req.body;
  if (!name) return res.status(400).json({ error: "Name required" });
  try {
    const connection = await pool.getConnection();
    try {
      await connection.beginTransaction();

      // Update sponsor
      await connection.execute("UPDATE sponsors SET name = ?, contact_info = ? WHERE id = ?", [name, contact_info, req.params.id]);

      // Update corresponding u_text in ads
      await connection.execute("UPDATE advertisements SET u_text = ? WHERE sponsor_id = ?", [name, req.params.id]);

      await connection.commit();
      res.json({ success: true });
    } catch (err) {
      await connection.rollback();
      throw err;
    } finally {
      connection.release();
    }
  } catch (e) { res.status(500).json({ error: e.message }); }
});

app.delete("/api/admin/sponsors/:id", authenticateAdmin, async (req, res) => {
  try {
    await pool.execute("DELETE FROM sponsors WHERE id = ?", [req.params.id]);
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// --- Settings Management ---
app.get("/api/admin/settings", authenticateAdmin, async (req, res) => {
  try {
    const [settings] = await pool.execute("SELECT * FROM system_settings");
    const settingsObj = {};
    settings.forEach(s => settingsObj[s.setting_key] = s.setting_value);
    res.json(settingsObj);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

app.post("/api/admin/settings", authenticateAdmin, async (req, res) => {
  const { settings } = req.body; // { key: value, ... }
  try {
    for (const [key, value] of Object.entries(settings)) {
      await pool.execute("INSERT INTO system_settings (setting_key, setting_value) VALUES (?, ?) ON DUPLICATE KEY UPDATE setting_value = ?", [key, String(value), String(value)]);
    }
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// --- Admin Book Management ---

// Add Sponsorship to Book
app.post("/api/admin/books/sponsor", authenticateAdmin, async (req, res) => {
  const { bookId, sponsorId, amount } = req.body;
  if (!bookId || !sponsorId || !amount) return res.status(400).json({ error: "Missing fields" });

  try {
    // Get rates
    const [settingsRows] = await pool.execute("SELECT * FROM system_settings");
    const settings = {};
    settingsRows.forEach(s => settings[s.setting_key] = s.setting_value);

    const rateAmount = parseFloat(settings['sponsorship_rate_amount'] || 1000);
    const rateCopies = parseInt(settings['sponsorship_rate_copies'] || 10);

    // Calculate copies
    const copiesToAdd = Math.floor((amount / rateAmount) * rateCopies);

    // Insert Record
    await pool.execute("INSERT INTO book_sponsors (book_id, sponsor_id, amount_paid, copies_added) VALUES (?, ?, ?, ?)",
      [bookId, sponsorId, amount, copiesToAdd]);

    // Update Book
    await pool.execute("UPDATE books SET total_copies = total_copies + ?, available_copies = available_copies + ? WHERE id = ?",
      [copiesToAdd, copiesToAdd, bookId]);

    // Process Queue if needed
    await processQueue(bookId);

    res.json({ success: true, copiesAdded: copiesToAdd });

  } catch (e) { res.status(500).json({ error: e.message }); }
});

// Get Admin Books (with sponsor data)
app.get("/api/admin/books", authenticateAdmin, async (req, res) => {
  try {
    const [books] = await pool.execute(`
            SELECT b.*, 
            (SELECT COUNT(*) FROM book_sponsors bs WHERE bs.book_id = b.id) as sponsor_count,
            (SELECT SUM(bs.amount_paid) FROM book_sponsors bs WHERE bs.book_id = b.id) as total_sponsored_amount
            FROM books b ORDER BY b.id DESC
        `);
    res.json(books);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// Delete Book
app.delete("/api/admin/books/:id", authenticateAdmin, async (req, res) => {
  // Basic delete
  try {
    await pool.execute("DELETE FROM books WHERE id = ?", [req.params.id]);
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// Update Book Metadata
app.put("/api/admin/books/:id", authenticateAdmin, upload.fields([{ name: 'document', maxCount: 1 }, { name: 'cover_image', maxCount: 1 }]), async (req, res) => {
  const { title, author, description, available_copies, total_copies } = req.body;
  const bookId = req.params.id;

  try {
    const documentFile = req.files && req.files["document"] ? req.files["document"][0] : null;
    const coverFile = req.files && req.files["cover_image"] ? req.files["cover_image"][0] : null;

    let updateQuery = "UPDATE books SET title = ?, author = ?, description = ?, available_copies = ?, total_copies = ?";
    let queryParams = [title, author, description, available_copies, total_copies];

    if (documentFile) {
      const fileExt = path.extname(documentFile.originalname).toLowerCase();
      let fileType = "txt";
      if (fileExt === ".pdf") fileType = "pdf";
      else if (fileExt === ".doc") fileType = "doc";
      else if (fileExt === ".docx") fileType = "docx";
      else if (fileExt === ".epub") fileType = "epub";

      const githubUrl = await uploadToGitHub(documentFile.buffer, documentFile.originalname, "documents");
      updateQuery += ", file_path = ?, file_type = ?, file_size = ?";
      queryParams.push(githubUrl, fileType, documentFile.size);
    }

    if (coverFile) {
      const coverUrl = await uploadToGitHub(coverFile.buffer, coverFile.originalname, "covers");
      updateQuery += ", cover_image = ?";
      queryParams.push(coverUrl);
    }

    updateQuery += " WHERE id = ?";
    queryParams.push(bookId);

    await pool.execute(updateQuery, queryParams);

    res.json({ success: true });
  } catch (e) {
    console.error("Update book error:", e);
    res.status(500).json({ error: e.message });
  }
});

// --- Ad Management ---

// Public: Get Ads for Section
// Public: Get Ads for Section (Optional: Filter by Sponsor)
app.get("/api/promos/section/:section", async (req, res) => {
  const { section } = req.params; // A, B, C
  const { sponsor_id } = req.query;

  try {
    let query = "SELECT * FROM advertisements WHERE section = ? AND is_active = TRUE";
    const params = [section];

    if (sponsor_id) {
      query += " AND sponsor_id = ?";
      params.push(sponsor_id);
    }

    query += " ORDER BY created_at DESC";

    const [ads] = await pool.execute(query, params);
    res.json(ads);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// Admin: Get All Ads
app.get("/api/admin/promos", authenticateAdmin, async (req, res) => {
  try {
    const [ads] = await pool.execute(`
        SELECT a.*, s.name as sponsor_name
        FROM advertisements a
        LEFT JOIN sponsors s ON a.sponsor_id = s.id
        ORDER BY a.created_at DESC
    `);
    res.json(ads);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// Admin: Get Single Book (with sponsor data)
app.get("/api/books/:id", authenticateAdmin, async (req, res) => {
  try {
    const [books] = await pool.execute(`
        SELECT b.*,
        JSON_ARRAYAGG(s.name) as sponsors,
        JSON_ARRAYAGG(s.id) as sponsor_ids,
        CASE WHEN COUNT(bs.sponsor_id) > 0 THEN TRUE ELSE FALSE END as is_sponsored
        FROM books b
        LEFT JOIN book_sponsors bs ON b.id = bs.book_id
        LEFT JOIN sponsors s ON bs.sponsor_id = s.id
        WHERE b.id = ?
        GROUP BY b.id
    `, [req.params.id]);

    if (books.length === 0) {
      return res.status(404).json({ error: "Book not found" });
    }

    const book = books[0];
    // JSON_ARRAYAGG returns a JSON string, parse it
    book.sponsors = book.sponsors ? JSON.parse(book.sponsors).filter(name => name !== null) : [];
    book.sponsor_ids = book.sponsor_ids ? JSON.parse(book.sponsor_ids).filter(id => id !== null) : [];

    res.json(book);
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// Admin: Upload/Create Ad
app.post("/api/admin/promos", authenticateAdmin, upload.fields([{ name: 'image', maxCount: 1 }, { name: 'logo', maxCount: 1 }]), async (req, res) => {
  try {
    const { section, u_text, redirect_link, is_sticky, sponsor_id } = req.body;
    const files = req.files || {};

    let image_path = null;
    let logo_path = null;

    if (files['image'] && files['image'][0]) {
      image_path = await uploadToGitHub(files['image'][0].buffer, files['image'][0].originalname, 'documents');
    }
    if (files['logo'] && files['logo'][0]) {
      logo_path = await uploadToGitHub(files['logo'][0].buffer, files['logo'][0].originalname, 'documents');
    }

    // Validate required fields based on section logic (optional but good practice)
    // Section A needs image, C needs image, B needs logo? 

    // Debug logging
    console.log("Ad Upload Payload:", { section, u_text, redirect_link, is_sticky, sponsor_id });
    console.log("Files:", files);

    // Validate required fields
    if (!section) {
      return res.status(400).json({ error: "Ad Section is required" });
    }

    // Ensure params are not undefined (use null)
    const safeText = u_text || null;
    const safeLink = redirect_link || null;
    const safeSticky = is_sticky === 'true'; // boolean (false if undefined)
    const safeSponsorId = sponsor_id ? parseInt(sponsor_id) : null;

    // Explicitly check section (though verified above)
    const safeSection = section || null;

    await pool.execute(
      "INSERT INTO advertisements (section, image_path, logo_path, u_text, redirect_link, is_sticky, sponsor_id) VALUES (?, ?, ?, ?, ?, ?, ?)",
      [safeSection, image_path, logo_path, safeText, safeLink, safeSticky, safeSponsorId]
    );

    res.json({ success: true });
  } catch (e) {
    console.error("Ad Upload Error", e);
    res.status(500).json({ error: e.message });
  }
});

// Admin: Toggle Ad Status
app.post("/api/admin/promos/:id/toggle", authenticateAdmin, async (req, res) => {
  try {
    await pool.execute("UPDATE advertisements SET is_active = NOT is_active WHERE id = ?", [req.params.id]);
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// Admin: Delete Ad
app.delete("/api/admin/promos/:id", authenticateAdmin, async (req, res) => {
  try {
    await pool.execute("DELETE FROM advertisements WHERE id = ?", [req.params.id]);
    res.json({ success: true });
  } catch (e) { res.status(500).json({ error: e.message }); }
});

// Admin: Update Ad
app.put("/api/admin/promos/:id", authenticateAdmin, upload.fields([{ name: 'image', maxCount: 1 }, { name: 'logo', maxCount: 1 }]), async (req, res) => {
  try {
    const { section, u_text, redirect_link, is_sticky, sponsor_id } = req.body;
    const files = req.files || {};
    const adId = req.params.id;

    let updateFields = [];
    let updateValues = [];

    if (section) { updateFields.push("section = ?"); updateValues.push(section); }
    if (u_text !== undefined) { updateFields.push("u_text = ?"); updateValues.push(u_text || null); }
    if (redirect_link !== undefined) { updateFields.push("redirect_link = ?"); updateValues.push(redirect_link || null); }
    if (is_sticky !== undefined) { updateFields.push("is_sticky = ?"); updateValues.push(is_sticky === 'true'); }
    if (sponsor_id) { updateFields.push("sponsor_id = ?"); updateValues.push(parseInt(sponsor_id)); }

    if (files['image'] && files['image'][0]) {
      const image_path = await uploadToGitHub(files['image'][0].buffer, files['image'][0].originalname, 'documents');
      updateFields.push("image_path = ?");
      updateValues.push(image_path);
    }
    if (files['logo'] && files['logo'][0]) {
      const logo_path = await uploadToGitHub(files['logo'][0].buffer, files['logo'][0].originalname, 'documents');
      updateFields.push("logo_path = ?");
      updateValues.push(logo_path);
    }

    if (updateFields.length > 0) {
      updateValues.push(adId);
      await pool.execute(
        `UPDATE advertisements SET ${updateFields.join(', ')} WHERE id = ?`,
        updateValues
      );
    }

    res.json({ success: true });
  } catch (e) {
    console.error("Ad Update Error", e);
    res.status(500).json({ error: e.message });
  }
});

// Books endpoints with queue information
// Update the books endpoint to include queue information
// Update the books endpoint to include proper queue information
// Books endpoints with queue information
app.get("/api/books", authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const [books] = await pool.execute("SELECT * FROM books");

    // Enhance each book with queue information for the current user AND sponsorship info
    const enhancedBooks = await Promise.all(
      books.map(async (book) => {
        // Fetch Sponsors
        const [sponsorsRows] = await pool.execute(
          `SELECT DISTINCT s.name FROM sponsors s 
             JOIN book_sponsors bs ON s.id = bs.sponsor_id 
             WHERE bs.book_id = ?`,
          [book.id]
        );
        const sponsors = sponsorsRows.map(r => r.name);
        const isSponsored = sponsors.length > 0;

        // Check if user has active rental for this book
        const [activeRentals] = await pool.execute(
          'SELECT * FROM rentals WHERE book_id = ? AND user_id = ? AND status = "active"',
          [book.id, userId]
        );

        const userHasRental = activeRentals.length > 0;

        // Get queue information for this book
        const [queueItems] = await pool.execute(
          `
    SELECT q.*, u.name, u.email 
    FROM queue q 
    JOIN users u ON q.user_id = u.id 
    WHERE q.book_id = ? 
    ORDER BY 
      CASE 
        WHEN q.status = 'available' THEN 1
        WHEN q.status = 'waiting' THEN 2
        ELSE 3
      END,
      q.added_at ASC
  `,
          [book.id]
        );

        // Find user's position and status
        const userQueueItem = queueItems.find(
          (item) => item.user_id === userId
        );
        const userPosition =
          queueItems.findIndex((item) => item.user_id === userId) + 1;
        const userInQueue = !!userQueueItem;
        const isFirstInQueue = userPosition === 1 && userInQueue;
        const hasReservation =
          userQueueItem && userQueueItem.status === "available";

        // Calculate if book is effectively available for this user
        // Book is effectively available only if user has an active reservation
        const effectiveAvailable = hasReservation;

        // Calculate time remaining for reservation
        let timeRemaining = null;
        if (hasReservation && userQueueItem.expires_at) {
          const expiryDate = new Date(userQueueItem.expires_at);
          timeRemaining = expiryDate - new Date();
        }

        return {
          ...book,
          sponsors,
          isSponsored,
          userHasRental,
          queueInfo: {
            totalInQueue: queueItems.length,
            userPosition: userInQueue ? userPosition : null,
            isFirstInQueue,
            userInQueue,
            hasReservation,
            effectiveAvailable,
            timeRemaining: timeRemaining > 0 ? timeRemaining : null,
            expiresAt: userQueueItem ? userQueueItem.expires_at : null,
            availableAt: userQueueItem ? userQueueItem.available_at : null,
            queueStatus: userQueueItem ? userQueueItem.status : null,
            // Add this to help frontend logic
            canJoinQueue: !userInQueue && book.available_copies <= 0,
          },
        };
      })
    );

    res.json(enhancedBooks);
  } catch (error) {
    console.error("Books fetch error:", error);
    res.status(500).json({ error: "Failed to fetch books" });
  }
});
// Get book document for reading
app.get("/api/books/:id/read", authenticateToken, async (req, res) => {
  const bookId = req.params.id;
  const userId = req.user.id;

  try {
    // Check if user has an active rental
    const [rentals] = await pool.execute(
      'SELECT * FROM rentals WHERE book_id = ? AND user_id = ? AND status = "active"',
      [bookId, userId]
    );

    if (rentals.length === 0) {
      return res.status(403).json({ error: "You do not have an active rental for this book" });
    }

    // Get book details
    const [books] = await pool.execute("SELECT * FROM books WHERE id = ?", [bookId]);
    if (books.length === 0) {
      return res.status(404).json({ error: "Book not found" });
    }

    const book = books[0];
    const filePath = book.file_path;

    if (!filePath) {
      return res.status(404).json({ error: "This book has no associated file" });
    }

    // If filePath is a full URL (GitHub raw), proxy it
    if (filePath.startsWith("http://") || filePath.startsWith("https://")) {
      try {
        const response = await axios.get(filePath, { responseType: "stream" });
        res.setHeader("Content-Type", response.headers["content-type"] || "application/octet-stream");
        const safeTitle = encodeURIComponent(book.title).replace(/'/g, "%27");
        res.setHeader("Content-Disposition", `inline; filename*=UTF-8''${safeTitle}`);
        response.data.pipe(res);
      } catch (proxyErr) {
        console.error("Proxy error:", proxyErr.message);
        res.status(502).json({ error: "Could not fetch book file from storage" });
      }
      return;
    }

    // Legacy local path — try to serve from disk (dev only, won't work on Render)
    return res.status(404).json({
      error: "Book file not available. Please contact support.",
    });

  } catch (error) {
    console.error("Read book error:", error);
    res.status(500).json({ error: "Failed to access book" });
  }
});


// Upload book endpoint (for admin)
app.post("/api/books/upload", upload.fields([{ name: "document" }, { name: "cover_image" }]), async (req, res) => {
  try {
    const { title, author, description, total_copies } = req.body;

    const documentFile = req.files && req.files["document"] ? req.files["document"][0] : null;
    const coverFile = req.files && req.files["cover_image"] ? req.files["cover_image"][0] : null;

    if (!documentFile) {
      return res.status(400).json({ error: "No document file uploaded" });
    }

    // Determine file type
    const fileExt = path.extname(documentFile.originalname).toLowerCase();
    let fileType = "txt";
    if (fileExt === ".pdf") fileType = "pdf";
    else if (fileExt === ".doc") fileType = "doc";
    else if (fileExt === ".docx") fileType = "docx";
    else if (fileExt === ".epub") fileType = "epub";

    // Upload book document to GitHub
    const githubUrl = await uploadToGitHub(documentFile.buffer, documentFile.originalname, "documents");

    // Upload cover image to GitHub if provided
    let coverUrl = null;
    if (coverFile) {
      coverUrl = await uploadToGitHub(coverFile.buffer, coverFile.originalname, "covers");
    }

    // Insert book into database
    const [result] = await pool.execute(
      "INSERT INTO books (title, author, description, total_copies, available_copies, file_path, file_type, file_size, cover_image) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
      [
        title,
        author,
        description,
        total_copies || 1,
        total_copies || 1,
        githubUrl,
        fileType,
        documentFile.size,
        coverUrl
      ]
    );

    res.json({
      success: true,
      message: "Book uploaded successfully",
      book: { id: result.insertId, title, author },
    });
  } catch (error) {
    console.error("Upload book error:", error);
    res.status(500).json({ error: "Failed to upload book" });
  }
});

// Get user rentals
app.get("/api/user/rentals", authenticateToken, async (req, res) => {
  const userId = req.user.id;

  try {
    console.log("Fetching rentals for user:", userId);

    const [rentals] = await pool.execute(
      `
        SELECT r.*, b.title, b.author, b.description 
        FROM rentals r 
        JOIN books b ON r.book_id = b.id 
        WHERE r.user_id = ? AND r.status = 'active'
        ORDER BY r.rented_at DESC
    `,
      [userId]
    );

    console.log("Found rentals:", rentals);
    res.json(rentals);
  } catch (error) {
    console.error("Fetch rentals error:", error);
    res
      .status(500)
      .json({ error: "Failed to fetch rentals: " + error.message });
  }
});

// Get user queue
app.get("/api/user/queue", authenticateToken, async (req, res) => {
  const userId = req.user.id;

  try {
    console.log("Fetching queue for user:", userId);

    const [queue] = await pool.execute(
      `
        SELECT q.*, b.title, b.author, b.description 
        FROM queue q 
        JOIN books b ON q.book_id = b.id 
        WHERE q.user_id = ?
        ORDER BY q.added_at DESC
    `,
      [userId]
    );

    console.log("Found queue items:", queue);
    res.json(queue);
  } catch (error) {
    console.error("Fetch queue error:", error);
    res.status(500).json({ error: "Failed to fetch queue: " + error.message });
  }
});

// Add to queue endpoint
// Update the add to queue endpoint
app.post("/api/queue/add", authenticateToken, async (req, res) => {
  const { bookId } = req.body;
  const userId = req.user.id;

  try {
    // Check if book exists
    const [books] = await pool.execute("SELECT * FROM books WHERE id = ?", [
      bookId,
    ]);
    if (books.length === 0) {
      return res.status(404).json({ error: "Book not found" });
    }

    const book = books[0];

    // Get queue information to check if there are people waiting
    const [queueItems] = await pool.execute(
      `
            SELECT * FROM queue 
            WHERE book_id = ? 
            ORDER BY added_at ASC
        `,
      [bookId]
    );

    // Allow joining queue if:
    // 1. Book is unavailable (available_copies <= 0), OR
    // 2. Book is available but there are people in queue (meaning it's reserved for first person)
    const canJoinQueue = book.available_copies <= 0 || queueItems.length > 0;

    if (!canJoinQueue && book.available_copies > 0) {
      return res.status(400).json({
        error: "Book is available for direct rental. No need to join queue.",
        available: true,
      });
    }

    // Check if already in queue
    const [existingQueue] = await pool.execute(
      "SELECT * FROM queue WHERE book_id = ? AND user_id = ?",
      [bookId, userId]
    );

    if (existingQueue.length > 0) {
      return res.status(400).json({ error: "Book already in your queue" });
    }

    // Check if user already has active rental
    const [existingRentals] = await pool.execute(
      'SELECT * FROM rentals WHERE book_id = ? AND user_id = ? AND status = "active"',
      [bookId, userId]
    );

    if (existingRentals.length > 0) {
      return res
        .status(400)
        .json({ error: "You already have this book rented" });
    }

    // Add to queue
    await pool.execute("INSERT INTO queue (book_id, user_id) VALUES (?, ?)", [
      bookId,
      userId,
    ]);

    // Get updated queue position
    const [updatedQueueItems] = await pool.execute(
      `
            SELECT * FROM queue 
            WHERE book_id = ? 
            ORDER BY added_at ASC
        `,
      [bookId]
    );

    const position =
      updatedQueueItems.findIndex((item) => item.user_id === userId) + 1;

    res.json({
      success: true,
      message: "Book added to queue",
      position,
      totalInQueue: updatedQueueItems.length,
      availableCopies: book.available_copies,
    });
  } catch (error) {
    console.error("Add to queue error:", error);
    res.status(500).json({ error: "Failed to add to queue" });
  }
});
// Remove from queue endpoint
app.delete("/api/queue/remove", authenticateToken, async (req, res) => {
  const { queueId } = req.body;
  const userId = req.user.id;

  try {
    await pool.execute("DELETE FROM queue WHERE id = ? AND user_id = ?", [
      queueId,
      userId,
    ]);

    res.json({ success: true, message: "Removed from queue" });
  } catch (error) {
    console.error("Remove from queue error:", error);
    res.status(500).json({ error: "Failed to remove from queue" });
  }
});

app.post("/api/books/return", authenticateToken, async (req, res) => {
  const { rentalId, bookId } = req.body;
  const userId = req.user.id;

  try {
    // Verify rental belongs to user
    const [rentals] = await pool.execute(
      'SELECT * FROM rentals WHERE id = ? AND user_id = ? AND status = "active"',
      [rentalId, userId]
    );

    if (rentals.length === 0) {
      return res.status(404).json({ error: "Rental not found" });
    }

    // Update rental status
    await pool.execute(
      'UPDATE rentals SET status = "returned", returned_at = CURRENT_TIMESTAMP WHERE id = ?',
      [rentalId]
    );

    // Update book availability
    await pool.execute(
      "UPDATE books SET available_copies = available_copies + 1 WHERE id = ?",
      [bookId]
    );

    console.log(`Book ${bookId} returned. Processing queue...`);

    // Process queue for this book IMMEDIATELY
    await processQueue(bookId);

    res.json({ success: true, message: "Book returned successfully" });
  } catch (error) {
    console.error("Return book error:", error);
    res.status(500).json({ error: "Failed to return book" });
  }
});
// Add a new endpoint to manually trigger queue processing (for testing)
app.post("/api/queue/process/:bookId", authenticateToken, async (req, res) => {
  const bookId = req.params.bookId;

  try {
    await processQueue(bookId);
    res.json({ success: true, message: "Queue processed successfully" });
  } catch (error) {
    console.error("Manual queue process error:", error);
    res.status(500).json({ error: "Failed to process queue" });
  }
});
// Rent book endpoint with queue priority
app.post("/api/books/rent", authenticateToken, async (req, res) => {
  const { bookId } = req.body;
  const userId = req.user.id;

  console.log("Rent request - User:", userId, "Book:", bookId);

  try {
    const [books] = await pool.execute("SELECT * FROM books WHERE id = ?", [
      bookId,
    ]);
    if (books.length === 0) {
      return res.status(404).json({ error: "Book not found" });
    }

    const book = books[0];

    // Check if user has an active reservation (book is available for them)
    const [userReservations] = await pool.execute(
      `
        SELECT * FROM queue 
        WHERE book_id = ? AND user_id = ? AND status = 'available'
    `,
      [bookId, userId]
    );

    const hasReservation = userReservations.length > 0;

    // If book is available but user doesn't have reservation, check if someone else does
    if (book.available_copies > 0 && !hasReservation) {
      const [activeReservations] = await pool.execute(
        `
          SELECT * FROM queue 
          WHERE book_id = ? AND status = 'available'
      `,
        [bookId]
      );

      // If there are active reservations, book is reserved for those users
      if (activeReservations.length > 0) {
        return res.status(400).json({
          error: "Book is reserved for users in queue",
          reserved: true,
          available: false,
        });
      }
    }

    // Allow rental if:
    // 1. Book is available AND user has reservation, OR
    // 2. Book is available AND no one has reservation
    const canRent =
      book.available_copies > 0 && (hasReservation || !hasReservation);

    if (!canRent) {
      return res.status(400).json({
        error: "Book not available for rental",
        available: false,
      });
    }

    const [existingRentals] = await pool.execute(
      'SELECT * FROM rentals WHERE book_id = ? AND user_id = ? AND status = "active"',
      [bookId, userId]
    );

    if (existingRentals.length > 0) {
      return res
        .status(400)
        .json({ error: "You already have this book rented" });
    }

    const dueDate = new Date();
    dueDate.setDate(dueDate.getDate() + 21);

    await pool.execute(
      "INSERT INTO rentals (book_id, user_id, due_date) VALUES (?, ?, ?)",
      [bookId, userId, dueDate]
    );

    await pool.execute(
      "UPDATE books SET available_copies = available_copies - 1 WHERE id = ?",
      [bookId]
    );

    // Remove user from queue (whether waiting or available)
    await pool.execute("DELETE FROM queue WHERE book_id = ? AND user_id = ?", [
      bookId,
      userId,
    ]);

    console.log(
      "Rental created successfully for user:",
      userId,
      "book:",
      bookId
    );

    res.json({
      success: true,
      message: "Book rented successfully for 21 days",
      dueDate: dueDate.toISOString(),
    });
  } catch (error) {
    console.error("Rent book error:", error);
    res.status(500).json({ error: "Failed to rent book" });
  }
});
// Get expiration statistics
app.get("/api/admin/expiration-stats", authenticateToken, async (req, res) => {
  try {
    // Get overdue rentals count
    const [overdueRentals] = await pool.execute(`
        SELECT COUNT(*) as count 
        FROM rentals 
        WHERE status = 'active' 
        AND due_date < NOW()
    `);

    // Get expiring soon rentals (within 12 hours)
    const [expiringSoonRentals] = await pool.execute(`
        SELECT COUNT(*) as count 
        FROM rentals 
        WHERE status = 'active' 
        AND due_date < DATE_ADD(NOW(), INTERVAL 12 HOUR)
        AND due_date > NOW()
    `);

    // Get expired queue reservations
    const [expiredQueueReservations] = await pool.execute(`
        SELECT COUNT(*) as count 
        FROM queue 
        WHERE status = 'available' 
        AND expires_at < NOW()
    `);

    // Get long-waiting queue users
    const [longWaitingQueue] = await pool.execute(`
        SELECT COUNT(*) as count 
        FROM queue 
        WHERE status = 'waiting' 
        AND added_at < DATE_SUB(NOW(), INTERVAL 2 DAY)
    `);

    res.json({
      success: true,
      stats: {
        overdueRentals: overdueRentals[0].count,
        expiringSoonRentals: expiringSoonRentals[0].count,
        expiredQueueReservations: expiredQueueReservations[0].count,
        longWaitingQueue: longWaitingQueue[0].count,
      },
    });
  } catch (error) {
    console.error("Expiration stats error:", error);
    res.status(500).json({ error: "Failed to get expiration stats" });
  }
});
// Get detailed queue information
app.get("/api/books/:id/queue-details", authenticateToken, async (req, res) => {
  const bookId = req.params.id;
  const userId = req.user.id;

  try {
    const [queueItems] = await pool.execute(
      `
        SELECT q.*, u.name, u.email 
        FROM queue q 
        JOIN users u ON q.user_id = u.id 
        WHERE q.book_id = ? 
        ORDER BY q.added_at ASC
    `,
      [bookId]
    );

    const userPosition =
      queueItems.findIndex((item) => item.user_id === userId) + 1;
    const userInQueue = queueItems.some((item) => item.user_id === userId);

    // Calculate time remaining for each position
    const queueWithTimeRemaining = queueItems.map((item, index) => {
      const joinDate = new Date(item.added_at);
      const expiryDate = new Date(joinDate.getTime() + 2 * 24 * 60 * 60 * 1000); // 2 days
      const now = new Date();
      const timeRemaining = expiryDate - now;

      return {
        ...item,
        position: index + 1,
        joinDate: item.added_at,
        expiryDate: expiryDate.toISOString(),
        timeRemaining: Math.max(0, timeRemaining),
        isExpired: timeRemaining <= 0,
      };
    });

    res.json({
      queue: queueWithTimeRemaining,
      userPosition: userInQueue ? userPosition : null,
      totalInQueue: queueItems.length,
      userInQueue,
    });
  } catch (error) {
    console.error("Queue details error:", error);
    res.status(500).json({ error: "Failed to get queue details" });
  }
});

// Queue cleanup endpoint (can be called manually or via cron)
app.post("/api/queue/cleanup", async (req, res) => {
  try {
    const cleaned = await cleanupExpiredQueue();
    res.json({ success: true, cleaned });
  } catch (error) {
    console.error("Queue cleanup error:", error);
    res.status(500).json({ error: "Failed to clean up queue" });
  }
});
// Change the download-test endpoint to NOT require authentication:
app.get("/api/books/:id/download-test", async (req, res) => {
  const bookId = req.params.id;

  try {
    // REMOVE the authentication check - for testing only
    // const [rentals] = await pool.execute(
    //   'SELECT * FROM rentals WHERE book_id = ? AND user_id = ? AND status = "active"',
    //   [bookId, userId]
    // );

    // if (rentals.length === 0) {
    //   return res.status(403).json({ error: 'You do not have permission to download this book' });
    // }

    // Get book details
    const [books] = await pool.execute("SELECT * FROM books WHERE id = ?", [
      bookId,
    ]);
    if (books.length === 0) {
      return res.status(404).json({ error: "Book not found" });
    }

    const book = books[0];

    let content = "";
    const fileExt = path.extname(book.file_path).toLowerCase();

    if (book.file_path.startsWith("http")) {
      // Download remote file from GitHub (or anywhere else)
      const response = await axios.get(book.file_path, { responseType: 'arraybuffer' });
      const dataBuffer = Buffer.from(response.data);

      if (fileExt === ".pdf") {
        const pdfData = await pdfParse(dataBuffer);
        content = pdfData.text;
      } else if (fileExt === ".docx" || fileExt === ".doc") {
        const result = await mammoth.extractRawText({ buffer: dataBuffer });
        content = result.value;
      } else if (fileExt === ".txt") {
        content = dataBuffer.toString("utf-8");
      } else {
        return res.status(400).json({ error: "Unsupported file format" });
      }
    } else {
      // Legacy local file logic
      const filePath = path.join(
        __dirname,
        book.file_path.replace(/^\/?documents\//, "documents/")
      );

      if (!fs.existsSync(filePath)) {
        return res.status(404).json({ error: "Book file not found on server" });
      }

      const dataBuffer = fs.readFileSync(filePath);

      if (fileExt === ".pdf") {
        const pdfData = await pdfParse(dataBuffer);
        content = pdfData.text;
      } else if (fileExt === ".docx" || fileExt === ".doc") {
        const result = await mammoth.extractRawText({ path: filePath });
        content = result.value;
      } else if (fileExt === ".txt") {
        content = dataBuffer.toString("utf-8");
      } else {
        return res.status(400).json({ error: "Unsupported file format" });
      }
    }

    // Send the text content as JSON response
    res.json({
      success: true,
      book: {
        id: book.id,
        title: book.title,
        author: book.author,
        content: content,
        fileType: book.file_type,
      },
    });
  } catch (error) {
    console.error("Download book error:", error);
    res.status(500).json({ error: "Failed to download book" });
  }
});
// Get queue info for specific book
app.get("/api/books/:id/queue-info", authenticateToken, async (req, res) => {
  const bookId = req.params.id;
  const userId = req.user.id;

  try {
    // Get queue count and user position
    const [queueItems] = await pool.execute(
      `
        SELECT q.*, u.name 
        FROM queue q 
        JOIN users u ON q.user_id = u.id 
        WHERE q.book_id = ? 
        ORDER BY q.added_at ASC
    `,
      [bookId]
    );

    const userPosition =
      queueItems.findIndex((item) => item.user_id === userId) + 1;
    const totalInQueue = queueItems.length;

    // Check if user is in queue
    const [userInQueue] = await pool.execute(
      "SELECT * FROM queue WHERE book_id = ? AND user_id = ?",
      [bookId, userId]
    );

    res.json({
      totalInQueue,
      userPosition: userInQueue.length > 0 ? userPosition : null,
      isInQueue: userInQueue.length > 0,
      queueList: queueItems.slice(0, 5), // Return first 5 in queue
    });
  } catch (error) {
    console.error("Queue info error:", error);
    res.status(500).json({ error: "Failed to get queue info" });
  }
});
// Global error sanitizer — never expose stack traces to clients
app.use((err, req, res, next) => {
  console.error("[ERROR]", err.stack || err.message || err);
  const status = err.status || err.statusCode || 500;
  res.status(status).json({ error: "Something went wrong. Please try again." });
});

// 404 catch-all
app.use((req, res) => {
  res.status(404).json({ error: "Route not found" });
});
// Start server
// Start server
async function startServer() {
  await initializeDatabase();

  // Clean up expired queue entries on startup
  console.log("Cleaning up expired queue entries on startup...");
  const queueCleaned = await cleanupExpiredQueue();
  console.log(`Cleaned ${queueCleaned} expired queue entries`);

  // Process expired rentals on startup
  console.log("Processing expired rentals on startup...");
  const rentalsProcessed = await processExpiredRentals();
  console.log(`Processed ${rentalsProcessed} expired rentals`);

  // Set up periodic queue cleanup (every hour)
  setInterval(cleanupExpiredQueue, 60 * 60 * 1000);

  // Set up periodic rental expiry check (every 5 minutes)
  setInterval(processExpiredRentals, 5 * 60 * 1000);

  app.listen(PORT, "0.0.0.0", () => {
    console.log(`Server running on port ${PORT} ✅`);
    console.log(`Visit: http://localhost:${PORT}`);
    console.log("Automatic systems running:");
    console.log("- Queue cleanup: every hour");
    console.log("- Rental expiry check: every 5 minutes");
  });
}

startServer().catch(console.error);
