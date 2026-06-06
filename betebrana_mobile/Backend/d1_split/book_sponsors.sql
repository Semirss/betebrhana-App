CREATE TABLE `book_sponsors` (
  `id` INTEGER NOT NULL,
  `book_id` INTEGER NOT NULL,
  `sponsor_id` INTEGER NOT NULL,
  `amount_paid` decimal(10,2) NOT NULL,
  `copies_added` INTEGER NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
);

--
-- Dumping data for table `book_sponsors`
--

INSERT INTO `book_sponsors` (`id`, `book_id`, `sponsor_id`, `amount_paid`, `copies_added`, `created_at`) VALUES
(1, 6, 1, 1000.00, 10, '2026-01-29 00:32:22'),
(2, 7, 1, 1000.00, 5, '2026-01-29 00:45:33'),
(3, 6, 2, 500.00, 2, '2026-01-29 01:16:48'),
(4, 17, 3, 3000.00, 30, '2026-01-29 01:51:33'),
(5, 12, 1, 100.00, 1, '2026-03-21 03:56:01'),
(6, 18, 3, 100.00, 1, '2026-03-23 09:12:08'),
(7, 18, 3, 1000.00, 10, '2026-03-24 11:39:22');

-- --------------------------------------------------------

--
-- Table structure for table `encryption_keys`
--
