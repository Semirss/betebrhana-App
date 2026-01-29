-- Add is_sticky to advertisements if missing
ALTER TABLE advertisements ADD COLUMN is_sticky BOOLEAN DEFAULT FALSE;
