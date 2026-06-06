CREATE TABLE `offline_access` (
  `id` INTEGER NOT NULL,
  `user_id` INTEGER NOT NULL,
  `book_id` INTEGER NOT NULL,
  `device_fingerprint` varchar(255) NOT NULL,
  `device_type` TEXT NOT NULL DEFAULT 'desktop',
  `expires_at` datetime NOT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `last_verified` datetime DEFAULT NULL,
  `is_active` INTEGER DEFAULT 1
);

-- --------------------------------------------------------

--
-- Table structure for table `queue`
--
