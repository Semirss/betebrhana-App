-- Fix rentals status enum
ALTER TABLE rentals MODIFY COLUMN status ENUM('active', 'returned', 'overdue', 'expired') DEFAULT 'active';

-- Add sponsor_id to advertisements
ALTER TABLE advertisements ADD COLUMN sponsor_id INT;
ALTER TABLE advertisements ADD CONSTRAINT fk_ad_sponsor FOREIGN KEY (sponsor_id) REFERENCES sponsors(id) ON DELETE SET NULL;
