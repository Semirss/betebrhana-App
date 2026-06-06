CREATE TABLE `advertisements` (
  `id` INTEGER NOT NULL,
  `section` TEXT NOT NULL,
  `image_path` varchar(500) DEFAULT NULL,
  `logo_path` varchar(500) DEFAULT NULL,
  `u_text` varchar(255) DEFAULT NULL,
  `redirect_link` varchar(500) DEFAULT NULL,
  `is_active` INTEGER DEFAULT 1,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `sponsor_id` INTEGER DEFAULT NULL,
  `is_sticky` INTEGER DEFAULT 0
);

--
-- Dumping data for table `advertisements`
--

INSERT INTO `advertisements` (`id`, `section`, `image_path`, `logo_path`, `u_text`, `redirect_link`, `is_active`, `created_at`, `sponsor_id`, `is_sticky`) VALUES
(1, 'A', 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/documents/1774311944116-263892674.png', 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/documents/1774311944803-657977539.png', NULL, 'https://semir-sultan.vercel.app', 1, '2026-01-29 00:56:48', 1, 0),
(2, 'B', 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/documents/1774311909653-208470818.png', 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/documents/1774311910401-149784933.png', 'BM INSURANCE CO', 'https://semir-sultan.vercel.app', 1, '2026-01-29 01:13:51', 1, 1),
(3, 'C', 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/documents/1774311929051-246226808.png', 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/documents/1774311929638-306057494.png', 'BM INSURANCE CO', 'https://semir-sultan.vercel.app', 1, '2026-01-29 01:15:10', 1, 0),
(5, 'B', 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/documents/1774271864786-234616668.png', 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/documents/1774271865838-953373655.png', 'MEEDISH CO', 'https://semir-sultan.vercel.app', 1, '2026-01-29 01:19:36', 2, 0),
(6, 'C', 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/documents/1774310114092-497491368.png', 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/documents/1774310114731-848846509.png', 'MEEDISH CO', 'https://semir-sultan.vercel.app', 1, '2026-01-29 01:20:03', 2, 0),
(7, 'A', 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/documents/1774310380390-5006987.png', 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/documents/1774310381014-177235122.png', NULL, 'https://semir-sultan.vercel.app', 1, '2026-01-29 01:38:17', 2, 0),
(8, 'C', 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/documents/1774312240023-820786509.png', 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/documents/1774312240546-767211361.png', 'GRAVITY TECKNOLOGY''S CO', 'https://semir-sultan.vercel.app', 1, '2026-01-29 01:52:28', 3, 0),
(9, 'B', 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/documents/1774312220152-865901801.png', 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/documents/1774312220879-290072997.png', 'GRAVITY TECKNOLOGY''S CO', 'https://semir-sultan.vercel.app', 1, '2026-01-29 01:52:59', 3, 0),
(10, 'A', 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/documents/1774312164859-144864298.png', 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/documents/1774312165519-239546500.png', NULL, 'https://semir-sultan.vercel.app', 1, '2026-01-29 01:53:25', 3, 0);

-- --------------------------------------------------------

--
-- Table structure for table `books`
--
