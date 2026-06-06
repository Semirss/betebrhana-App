CREATE TABLE `encryption_keys` (
  `id` varchar(255) NOT NULL,
  `user_id` INTEGER NOT NULL,
  `book_id` INTEGER NOT NULL,
  `key_data` text NOT NULL,
  `device_fingerprint` varchar(255) NOT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `expires_at` datetime NOT NULL,
  `used_at` datetime DEFAULT NULL
);

--
-- Dumping data for table `encryption_keys`
--

INSERT INTO `encryption_keys` (`id`, `user_id`, `book_id`, `key_data`, `device_fingerprint`, `created_at`, `expires_at`, `used_at`) VALUES
('6a6605c3-00b4-4480-b70a-6d008a8bc328', 1, 6, 'ea1e1ea771cd71fc7fc1bd399e0e0b548fec93bc0b41e20ec168f9d567c1f088', '7db5fc750cbbf80c04150867e13af1f6e1ab694a03d95d1be3920e954439ac7f', '2025-10-30 16:04:08', '2025-10-30 17:04:08', '2025-10-30 16:04:08'),
('e4c41d22-8831-4ef1-b47e-68d0cffb0e98', 1, 6, '04214da90b2acc3c279356a975d4272c36ccf8bcea1fd4adeecb47b247ac97dd', '7db5fc750cbbf80c04150867e13af1f6e1ab694a03d95d1be3920e954439ac7f', '2025-10-30 16:03:51', '2025-10-30 17:03:51', '2025-10-30 16:03:51'),
('ee57961b-8da2-476d-ba06-1bd2d8f8fa23', 1, 6, '1e3f5e9d2b7638ea4973f0dfa2364342a89f412dc5d9d44fb407455453e2a31f', '7db5fc750cbbf80c04150867e13af1f6e1ab694a03d95d1be3920e954439ac7f', '2025-10-30 16:02:55', '2025-10-30 17:02:55', '2025-10-30 16:02:55');

-- --------------------------------------------------------

--
-- Table structure for table `offline_access`
--
