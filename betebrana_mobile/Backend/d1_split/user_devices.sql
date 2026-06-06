CREATE TABLE `user_devices` (
  `id` INTEGER NOT NULL,
  `user_id` INTEGER NOT NULL,
  `device_fingerprint` varchar(255) NOT NULL,
  `device_type` TEXT NOT NULL,
  `device_name` varchar(255) DEFAULT NULL,
  `last_used` datetime DEFAULT CURRENT_TIMESTAMP,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `is_active` INTEGER DEFAULT 1
);

--
-- Dumping data for table `user_devices`
--

INSERT INTO `user_devices` (`id`, `user_id`, `device_fingerprint`, `device_type`, `device_name`, `last_used`, `created_at`, `is_active`) VALUES
(1, 2, '7db5fc750cbbf80c04150867e13af1f6e1ab694a03d95d1be3920e954439ac7f', 'desktop', NULL, '2025-10-30 16:22:10', '2025-10-30 15:19:54', 1),
(5, 1, '1944a1fde9ed3f46f86b6de664d3ef56bcf78898e21bbc3a37503f665998a0b0', 'desktop', NULL, '2025-10-30 15:50:30', '2025-10-30 15:50:30', 1),
(6, 1, '7db5fc750cbbf80c04150867e13af1f6e1ab694a03d95d1be3920e954439ac7f', 'desktop', NULL, '2025-10-30 16:21:08', '2025-10-30 15:53:48', 1);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `admin_users`
--


--
-- Indexes for table `advertisements`
--


--
-- Indexes for table `books`
--


--
-- Indexes for table `book_sponsors`
--


--
-- Indexes for table `encryption_keys`
--


--
-- Indexes for table `offline_access`
--


--
-- Indexes for table `queue`
--


--
-- Indexes for table `reading_progress`
--


--
-- Indexes for table `rentals`
--


--
-- Indexes for table `sponsors`
--


--
-- Indexes for table `system_settings`
--


--
-- Indexes for table `users`
--


--
-- Indexes for table `user_devices`
--


--
-- AUTOINCREMENT for dumped tables
--

--
-- AUTOINCREMENT for table `admin_users`
--


--
-- AUTOINCREMENT for table `advertisements`
--


--
-- AUTOINCREMENT for table `books`
--


--
-- AUTOINCREMENT for table `book_sponsors`
--


--
-- AUTOINCREMENT for table `offline_access`
--


--
-- AUTOINCREMENT for table `queue`
--


--
-- AUTOINCREMENT for table `reading_progress`
--


--
-- AUTOINCREMENT for table `rentals`
--


--
-- AUTOINCREMENT for table `sponsors`
--


--
-- AUTOINCREMENT for table `users`
--


--
-- AUTOINCREMENT for table `user_devices`
--


--
-- Constraints for dumped tables
--

--
-- Constraints for table `advertisements`
--


--
-- Constraints for table `book_sponsors`
--


--
-- Constraints for table `encryption_keys`
--


--
-- Constraints for table `offline_access`
--


--
-- Constraints for table `queue`
--


--
-- Constraints for table `reading_progress`
--


--
-- Constraints for table `rentals`
--


--
-- Constraints for table `user_devices`
--
