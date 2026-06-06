CREATE TABLE `admin_users` (
  `id` INTEGER NOT NULL,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
);

--
-- Dumping data for table `admin_users`
--

INSERT INTO `admin_users` (`id`, `email`, `password`, `name`, `created_at`) VALUES
(1, 'admin@betebrana.com', '$2a$10$8wxwF8D8nvue8FyN.BrGAOIit54k0142A8xpoG88IQxxjGeOGmE3i', 'Super Admin', '2026-01-29 00:28:46');

-- --------------------------------------------------------

--
-- Table structure for table `advertisements`
--
