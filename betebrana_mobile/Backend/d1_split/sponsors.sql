CREATE TABLE `sponsors` (
  `id` INTEGER NOT NULL,
  `name` varchar(255) NOT NULL,
  `contact_info` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
);

--
-- Dumping data for table `sponsors`
--

INSERT INTO `sponsors` (`id`, `name`, `contact_info`, `created_at`) VALUES
(1, 'BM INSURANCE CO', '09643728922', '2026-01-29 00:31:48'),
(2, 'MEEDISH CO', 'MEEDISH@GMAIL.COM', '2026-01-29 01:12:55'),
(3, 'GRAVITY TECKNOLOGY''S CO', 'gravity@gmail.com', '2026-01-29 01:51:08');

-- --------------------------------------------------------

--
-- Table structure for table `system_settings`
--
