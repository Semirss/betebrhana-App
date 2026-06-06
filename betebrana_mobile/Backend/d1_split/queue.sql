CREATE TABLE `queue` (
  `id` INTEGER NOT NULL,
  `book_id` INTEGER DEFAULT NULL,
  `user_id` INTEGER DEFAULT NULL,
  `added_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `available_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `status` TEXT DEFAULT 'waiting'
);

--
-- Dumping data for table `queue`
--

INSERT INTO `queue` (`id`, `book_id`, `user_id`, `added_at`, `available_at`, `expires_at`, `status`) VALUES
(132, 10, 2, '2026-06-05 13:15:16', NULL, NULL, 'waiting');

-- --------------------------------------------------------

--
-- Table structure for table `reading_progress`
--
