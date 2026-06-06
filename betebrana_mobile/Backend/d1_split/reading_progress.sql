CREATE TABLE `reading_progress` (
  `id` INTEGER NOT NULL,
  `user_id` INTEGER DEFAULT NULL,
  `book_id` INTEGER DEFAULT NULL,
  `progress` float DEFAULT 0,
  `last_page` INTEGER DEFAULT 1,
  `last_read` timestamp NULL DEFAULT CURRENT_TIMESTAMP
);

-- --------------------------------------------------------

--
-- Table structure for table `rentals`
--
