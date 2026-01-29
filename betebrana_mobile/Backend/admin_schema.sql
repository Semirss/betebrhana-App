-- Admin Users Table
CREATE TABLE IF NOT EXISTS admin_users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sponsors Table
CREATE TABLE IF NOT EXISTS sponsors (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    contact_info TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- System Settings Table (for configurable constants)
CREATE TABLE IF NOT EXISTS system_settings (
    setting_key VARCHAR(50) PRIMARY KEY,
    setting_value VARCHAR(255) NOT NULL,
    description TEXT
);

-- Seed default settings
INSERT IGNORE INTO system_settings (setting_key, setting_value, description) VALUES 
('sponsorship_rate_amount', '1000', 'Cost for one batch of sponsorship'),
('sponsorship_rate_copies', '10', 'Number of book copies added per batch');

-- Book Sponsors Table (Link between books and sponsors)
CREATE TABLE IF NOT EXISTS book_sponsors (
    id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    sponsor_id INT NOT NULL,
    amount_paid DECIMAL(10, 2) NOT NULL,
    copies_added INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE,
    FOREIGN KEY (sponsor_id) REFERENCES sponsors(id) ON DELETE CASCADE
);

-- Advertisements Table
CREATE TABLE IF NOT EXISTS advertisements (
    id INT AUTO_INCREMENT PRIMARY KEY,
    section ENUM('A', 'B', 'C') NOT NULL, -- A: Hero Slider, B: Bottom Banner, C: Full Screen
    image_path VARCHAR(500), -- For Slider/Full Screen
    logo_path VARCHAR(500), -- For Bottom Banner
    u_text VARCHAR(255), -- Short text/Overlay
    redirect_link VARCHAR(500),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
