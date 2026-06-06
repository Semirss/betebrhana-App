-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Jun 05, 2026 at 02:16 PM
-- Server version: 10.6.26-MariaDB
-- PHP Version: 8.2.30











--
-- Database: `motobime_betebrana`
--

-- --------------------------------------------------------

--
-- Table structure for table `admin_users`
--

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

CREATE TABLE `books` (
  `id` INTEGER NOT NULL,
  `title` varchar(255) NOT NULL,
  `author` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `total_copies` INTEGER DEFAULT 1,
  `available_copies` INTEGER DEFAULT 1,
  `file_path` varchar(500) DEFAULT NULL,
  `file_type` TEXT DEFAULT NULL,
  `file_size` INTEGER DEFAULT NULL,
  `cover_image` varchar(500) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
);

--
-- Dumping data for table `books`
--

INSERT INTO `books` (`id`, `title`, `author`, `description`, `total_copies`, `available_copies`, `file_path`, `file_type`, `file_size`, `cover_image`, `created_at`) VALUES
(6, 'ጦቢያ (Tobiya)', 'አፈወርቅ ገብረኢየሱስ ', 'ጦቢያ\" በአማርኛ የመጀመሪያው ልቦለድ ነው ተብሎ በሰፊው ይነገራል።  (ታሪኩ ስለ ዋህድ እና እህቱ ጦቢያ ነው።) ደራሲ፡- አፈወርቅ ገብረየሱስ 1900 - ሮም  \"Tobia \" It is widely considered the first novel in Amharic. (The story is about Waḥed and his sister Ṭobia.) Author:- Afework Gebreyesus  1908, Rome.', 13, 12, 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/documents/document-1760881771279-235542173.txt', 'txt', 29350, 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/covers/1774314991103-373392120.jpg', '2025-10-19 13:49:31'),
(7, 'አ(ABETSELOM)', ' ተሰማ ብርሃኑ', 'በመጀመሪያ 1900 ዓ.ም. በሮማ ከተማ ታተመ፡፡በመጀመሪያ 1900 ዓ.ም. በሮማ ከተማ ታተመ፡፡በመጀመሪያ 1900 ዓ.ም. በሮማ ከተማ ታተመ፡፡በመጀመሪያ 1900 ዓ.ም. በሮማ ከተማ ታተመ፡፡በመጀመሪያ 1900 ዓ.ም. በሮማ ከተማ ታተመ፡፡በመጀመሪያ 1900 ዓ.ም. በሮማ ከተማ ታተመ፡፡በመጀመሪያ 1900 ዓ.ም. በሮማ ከተማ ታተመ፡፡በመጀመሪያ 1900 ዓ.ም. በሮማ ከተማ ታተመ፡፡በመጀመሪያ 1900 ዓ.ም. በሮማ ከተማ ታተመ፡፡በመጀመሪያ 1900 ዓ.ም. በሮማ ከተማ ታተመ፡፡በመጀመሪያ 1900 ዓ.ም. በሮማ ከተማ ታተመ፡፡', 6, 6, 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/documents/try.pdf', 'pdf', 29350, 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/covers/hijaced1.jpg', '2025-10-19 13:49:31'),
(8, 'ፍቅር በአዲስ አበባ', 'ብርሃኑ ተሰማ', 'ምስል የሚሰጥ የፍቅር ታሪክ በአዲስ አበባ ውስጥ የሚደረግ እንቅስቃሴ', 0, 0, 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/documents/love_in_addis.txt', 'txt', 24500, 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/covers/hijaced2.jpg', '2025-12-05 07:00:00'),
(9, 'የኢትዮጵያ ታሪክ', 'ዶክተር ዘሪሁን ማሞ', 'ከጥንት እስከ ዘመናዊ የኢትዮጵያ ታሪክ ማጠቃለያ', 0, 0, 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/documents/ethiopian_history.txt', 'txt', 37800, 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/covers/hijaced3.jpg', '2025-12-05 07:05:00'),
(10, 'ልጆች ለልጆች', 'ሄለን ነጋሽ', 'ለልጆች የተጻፉ የሚያስቡ ታሪኮች እና ምክሮች', 0, 0, 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/documents/children_stories.txt', 'txt', 15600, 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/covers/hijaced4.jpg', '2025-12-05 07:10:00'),
(11, 'የገበሬ ህይወት', 'ጌታቸው ታደሰ', 'የኢትዮጵያ ገበሬ ቀንበር እና የህይወት ተጋድሎ', 0, 0, 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/documents/farmer_life.txt', 'txt', 28900, 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/covers/hijaced5.jpg', '2025-12-05 07:15:00'),
(12, 'የቃላት ጥበብ', 'ፍቅር መኮንን', 'የአማርኛ ቋንቋ ትክክለኛ አጠቃቀም እና የቃላት ስልት', 1, 1, 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/documents/language_wisdom.txt', 'txt', 31200, 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/covers/hijaced6.jpg', '2025-12-05 07:20:00'),
(13, 'አርቲስቶች ዓለም', 'ሙሉጌታ ላም', 'የኢትዮጵያ አርቲስቶች ህይወት እና ስራ', 0, 0, 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/documents/artists_world.txt', 'txt', 26700, 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/covers/hijaced7.jpg', '2025-12-05 07:25:00'),
(14, 'የቤተሰብ ግንኙነት', 'ደራስ ተክለሃይማኖት', 'ዘመናዊ የቤተሰብ ግንኙነት እና ህይወት ምክሮች', 0, 0, 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/documents/family_relationship.txt', 'txt', 30100, 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/covers/hijaced8.jpg', '2025-12-05 07:30:00'),
(15, 'ኢንተርኔት እና ማህበረሰብ', 'አብይ ሻምበል', 'ዘመናዊ ቴክኖሎጂ በኢትዮጵያ ማህበረሰብ ላይ ያለው ተጽዕኖ', 0, 0, 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/documents/internet_society.txt', 'txt', 32800, 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/covers/hijaced9.jpg', '2025-12-05 07:35:00'),
(16, 'የጤና መመሪያ', 'ዶክተር ሜሪ አባተ', 'መሰረታዊ የጤና ጥንቃቄዎች እና መከላከያ ዘዴዎች', 0, 0, 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/documents/health_guide.txt', 'txt', 25600, 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/covers/hijaced10.jpg', '2025-12-05 07:40:00'),
(17, 'የንግድ ስኬት', 'ሳሙኤል ገብረማርያም', 'አነስተኛ ንግድ ለመጀመር እና ለማስፋፋት የሚረዱ ምክሮች', 30, 30, 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/documents/business_success.txt', 'txt', 29400, 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/covers/hijaced11.jpg', '2025-12-05 07:45:00'),
(18, 'pdf hj', 'semir', 'kj', 11, 10, 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/documents/1774257106716-874578491.pdf', 'pdf', 100810, 'https://raw.githubusercontent.com/Semirss/betebrhana-App/main/betebrana_mobile/Backend/covers/1774257107725-216244348.jpg', '2026-03-23 09:11:48');

-- --------------------------------------------------------

--
-- Table structure for table `book_sponsors`
--

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

CREATE TABLE `rentals` (
  `id` INTEGER NOT NULL,
  `book_id` INTEGER DEFAULT NULL,
  `user_id` INTEGER DEFAULT NULL,
  `rented_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `due_date` timestamp NULL DEFAULT NULL,
  `returned_at` timestamp NULL DEFAULT NULL,
  `status` TEXT DEFAULT 'active'
);

--
-- Dumping data for table `rentals`
--

INSERT INTO `rentals` (`id`, `book_id`, `user_id`, `rented_at`, `due_date`, `returned_at`, `status`) VALUES
(13, 6, 1, '2025-10-19 22:28:11', '2025-11-09 22:28:11', '2025-10-19 23:07:59', 'returned'),
(25, 6, 2, '2025-10-20 06:37:29', '2025-11-10 06:37:30', '2025-10-20 12:22:13', 'returned'),
(29, 6, 2, '2025-10-20 12:22:17', '2025-11-10 12:22:17', '2025-10-20 12:45:08', 'returned'),
(33, 6, 2, '2025-10-20 13:19:12', '2025-11-10 13:19:12', '2025-10-20 14:11:12', 'returned'),
(34, 6, 2, '2025-10-20 14:11:14', '2025-11-10 14:11:15', '2025-10-20 14:11:21', 'returned'),
(35, 6, 2, '2025-10-20 14:11:25', '2025-11-10 14:11:25', '2025-10-21 01:01:39', 'returned'),
(36, 6, 2, '2025-10-21 01:02:36', '2025-11-11 01:02:37', '2025-10-21 01:25:09', 'returned'),
(37, 6, 1, '2025-10-21 01:25:29', '2025-11-11 01:25:29', '2025-10-21 01:41:06', 'returned'),
(38, 6, 2, '2025-10-21 01:44:22', '2025-11-11 01:44:22', '2025-10-21 01:45:53', 'returned'),
(39, 6, 1, '2025-10-21 01:55:45', '2025-11-11 01:55:46', '2025-10-21 01:56:23', 'returned'),
(40, 6, 2, '2025-10-21 01:56:37', '2025-11-11 01:56:38', '2025-10-21 07:34:35', 'returned'),
(41, 6, 1, '2025-10-21 07:35:15', '2025-11-11 07:35:16', '2025-10-21 12:37:22', 'returned'),
(42, 6, 2, '2025-10-23 10:15:47', '2025-11-13 10:15:47', '2025-10-23 10:26:51', 'returned'),
(43, 6, 1, '2025-10-23 10:48:06', '2025-11-13 10:48:07', '2025-10-23 10:53:40', 'returned'),
(44, 6, 1, '2025-10-23 10:58:03', '2025-11-13 10:58:03', '2025-10-23 11:00:27', 'returned'),
(45, 6, 2, '2025-10-23 11:00:46', '2025-11-13 11:00:47', '2025-10-23 11:04:52', 'returned'),
(46, 6, 1, '2025-10-23 11:11:43', '2025-11-13 11:11:43', '2025-10-23 11:12:17', 'returned'),
(47, 6, 2, '2025-10-23 11:14:04', '2025-11-13 11:14:05', '2025-10-23 11:28:12', 'returned'),
(48, 6, 1, '2025-10-23 11:31:21', '2025-11-13 11:31:21', '2025-10-23 11:31:31', 'returned'),
(49, 6, 2, '2025-10-23 11:32:43', '2025-11-13 11:32:43', '2025-10-23 11:32:57', 'returned'),
(50, 6, 1, '2025-10-23 11:33:16', '2025-11-13 11:33:17', '2025-10-23 11:33:26', 'returned'),
(51, 6, 2, '2025-10-23 11:34:23', '2025-11-13 11:34:24', '2025-10-23 11:34:58', 'returned'),
(52, 6, 1, '2025-10-23 11:35:03', '2025-11-13 11:35:03', '2025-10-23 11:35:04', 'returned'),
(53, 6, 1, '2025-10-23 11:35:35', '2025-11-13 11:35:35', '2025-10-23 11:35:42', 'returned'),
(54, 6, 2, '2025-10-23 11:35:50', '2025-11-13 11:35:51', '2025-10-23 11:36:14', 'returned'),
(55, 6, 1, '2025-10-23 11:36:56', '2025-11-13 11:36:56', '2025-10-23 11:37:47', 'returned'),
(56, 6, 2, '2025-10-23 11:38:13', '2025-11-13 11:38:14', '2025-10-23 11:51:36', 'returned'),
(57, 6, 2, '2025-10-23 11:51:45', '2025-11-13 11:51:46', '2025-10-23 11:52:11', 'returned'),
(58, 6, 1, '2025-10-23 11:53:45', '2025-11-13 11:53:45', '2025-10-23 11:54:04', 'returned'),
(59, 6, 1, '2025-10-23 11:54:22', '2025-11-13 11:54:23', '2025-10-23 12:43:53', 'returned'),
(60, 6, 2, '2025-10-23 12:50:11', '2025-11-13 12:50:12', '2025-10-23 12:54:19', 'returned'),
(61, 6, 1, '2025-10-23 12:55:29', '2025-11-13 12:55:30', '2025-10-23 12:59:58', 'returned'),
(62, 6, 1, '2025-10-23 13:03:50', '2025-11-13 13:03:51', '2025-10-23 13:34:50', 'returned'),
(63, 6, 1, '2025-10-28 10:49:31', '2025-11-18 10:49:32', '2025-10-29 10:46:26', 'returned'),
(64, 6, 2, '2025-10-29 10:46:37', '2025-11-19 10:46:38', '2025-10-29 10:46:55', 'returned'),
(65, 6, 1, '2025-10-29 10:47:13', '2025-11-19 10:47:13', '2025-10-29 10:47:22', 'returned'),
(66, 6, 2, '2025-10-29 10:47:34', '2025-11-19 10:47:35', '2025-10-30 12:46:20', 'returned'),
(67, 6, 1, '2025-10-30 12:50:32', '2025-11-20 12:50:32', '2025-10-30 13:31:34', 'returned'),
(68, 6, 2, '2025-10-30 13:31:40', '2025-11-20 13:31:40', '2025-10-30 14:19:54', 'returned'),
(69, 6, 1, '2025-10-30 14:20:03', '2025-11-20 14:20:03', '2025-10-30 14:20:11', 'returned'),
(70, 6, 1, '2025-10-30 14:20:34', '2025-11-20 14:20:34', '2025-10-30 14:20:48', 'returned'),
(71, 6, 2, '2025-10-30 14:21:27', '2025-11-20 14:21:27', '2025-10-30 14:21:36', 'returned'),
(72, 6, 1, '2025-10-30 14:21:43', '2025-11-20 14:21:43', '2025-10-30 15:42:59', 'returned'),
(73, 6, 1, '2025-10-30 15:44:01', '2025-11-20 15:44:01', '2025-10-31 08:30:54', 'returned'),
(74, 6, 1, '2025-10-31 08:31:27', '2025-11-21 08:31:28', '2025-10-31 08:34:50', 'returned'),
(75, 6, 1, '2025-10-31 08:34:56', '2025-11-21 08:34:57', '2025-10-31 11:25:56', 'returned'),
(76, 6, 1, '2025-10-31 11:25:58', '2025-11-21 11:25:59', '2025-11-02 04:42:49', 'returned'),
(77, 6, 2, '2025-11-02 04:43:49', '2025-11-23 04:43:49', '2025-11-02 04:48:43', 'returned'),
(78, 6, 1, '2025-11-02 04:50:46', '2025-11-23 04:50:46', '2025-11-02 07:58:46', 'returned'),
(79, 6, 2, '2025-11-02 07:59:18', '2025-11-23 07:59:19', '2025-11-02 11:19:38', 'returned'),
(80, 6, 1, '2025-11-02 11:20:11', '2025-11-23 11:20:11', '2025-11-05 22:22:40', 'returned'),
(81, 7, 2, '2025-11-05 13:19:38', '2025-11-26 13:19:38', '2025-11-05 21:57:00', 'returned'),
(82, 7, 1, '2025-11-05 21:58:32', '2025-11-26 21:58:33', '2025-11-05 21:59:07', 'returned'),
(83, 6, 2, '2025-11-05 22:23:38', '2025-11-26 22:23:38', '2025-11-05 22:27:25', 'returned'),
(84, 6, 1, '2025-11-05 22:27:59', '2025-11-26 22:27:59', '2025-11-07 14:17:51', 'returned'),
(85, 7, 2, '2025-11-05 22:41:38', '2025-11-26 22:41:39', '2025-11-05 22:42:21', 'returned'),
(86, 7, 2, '2025-11-05 23:14:24', '2025-11-26 23:14:24', '2025-11-08 22:13:21', 'returned'),
(87, 6, 1, '2025-11-07 14:17:52', '2025-11-28 14:17:53', '2025-11-08 22:03:44', 'returned'),
(88, 6, 1, '2025-11-08 22:03:46', '2025-11-29 22:03:46', '2025-11-08 22:12:15', 'returned'),
(89, 6, 3, '2025-11-08 22:12:31', '2025-11-29 22:12:32', '2025-11-08 22:12:39', 'returned'),
(90, 6, 2, '2025-11-08 22:13:17', '2025-11-29 22:13:18', '2025-11-08 22:13:51', 'returned'),
(91, 6, 1, '2025-11-08 22:13:57', '2025-11-29 22:13:58', '2025-11-11 11:27:04', 'returned'),
(92, 7, 1, '2025-11-11 09:45:57', '2025-12-02 09:45:58', '2025-11-11 09:47:05', 'returned'),
(93, 6, 1, '2025-11-11 11:31:47', '2025-12-02 11:31:47', '2025-11-11 11:35:04', 'returned'),
(94, 7, 1, '2025-11-11 11:34:44', '2025-12-02 11:34:45', '2025-11-11 11:35:06', 'returned'),
(95, 6, 1, '2025-11-14 11:39:35', '2025-12-05 11:39:35', '2025-11-14 11:40:18', 'returned'),
(96, 6, 1, '2025-11-14 11:40:53', '2025-12-05 11:40:54', '2025-11-14 11:45:53', 'returned'),
(97, 6, 1, '2025-11-14 12:05:09', '2025-12-05 12:05:09', '2025-11-14 12:05:37', 'returned'),
(98, 6, 2, '2025-11-14 12:27:40', '2025-12-05 12:27:41', '2025-11-14 12:27:50', 'returned'),
(99, 6, 2, '2025-11-14 12:27:54', '2025-12-05 12:27:54', '2025-11-14 12:36:30', 'returned'),
(100, 7, 1, '2025-11-14 12:28:36', '2025-12-05 12:28:37', '2025-11-14 12:42:55', 'returned'),
(101, 6, 1, '2025-11-14 12:36:51', '2025-12-05 12:36:52', '2025-11-14 12:37:03', 'returned'),
(102, 6, 2, '2025-11-14 12:42:09', '2025-12-05 12:42:09', '2025-11-15 06:03:28', 'returned'),
(103, 7, 2, '2025-11-14 12:47:29', '2025-12-05 12:47:29', '2025-11-14 12:47:34', 'returned'),
(104, 7, 1, '2025-11-14 12:48:25', '2025-12-05 12:48:26', '2025-11-14 12:49:03', 'returned'),
(105, 7, 2, '2025-11-14 12:49:09', '2025-12-05 12:49:09', '2025-11-14 12:56:41', 'returned'),
(106, 7, 1, '2025-11-14 12:57:13', '2025-12-05 12:57:14', '2025-11-14 12:58:10', 'returned'),
(107, 7, 2, '2025-11-14 13:36:46', '2025-12-05 13:36:47', '2025-11-15 06:04:18', 'returned'),
(108, 7, 2, '2025-11-15 06:44:54', '2025-12-06 06:44:54', '2025-11-15 06:57:09', 'returned'),
(109, 6, 1, '2025-11-15 06:46:24', '2025-12-06 06:46:25', '2025-11-15 06:47:09', 'returned'),
(110, 6, 2, '2025-11-15 06:47:37', '2025-12-06 06:47:38', '2025-11-15 06:48:29', 'returned'),
(111, 6, 2, '2025-11-15 06:48:47', '2025-12-06 06:48:47', '2025-11-15 06:55:41', 'returned'),
(112, 6, 2, '2025-11-15 06:56:37', '2025-12-06 06:56:37', '2025-11-15 06:57:42', 'returned'),
(113, 6, 2, '2025-11-15 06:57:53', '2025-12-06 06:57:53', '2025-11-26 08:47:06', 'returned'),
(114, 7, 2, '2025-11-15 06:58:19', '2025-12-06 06:58:19', '2025-11-18 02:02:54', 'returned'),
(115, 7, 2, '2025-11-18 02:10:10', '2025-12-09 02:10:11', '2025-11-18 02:10:16', 'returned'),
(116, 7, 2, '2025-11-25 22:15:29', '2025-12-16 22:15:29', '2025-11-25 22:15:32', 'returned'),
(117, 7, 2, '2025-11-26 08:46:14', '2025-12-17 08:46:14', '2025-11-26 08:47:32', 'returned'),
(118, 6, 1, '2025-11-26 08:47:58', '2025-12-17 08:47:59', '2025-11-29 16:37:23', 'returned'),
(119, 7, 2, '2025-11-28 08:06:12', '2025-12-19 08:06:13', '2025-12-02 14:02:51', 'returned'),
(120, 6, 1, '2025-11-29 16:37:31', '2025-12-20 16:37:31', '2025-11-29 16:52:11', 'returned'),
(121, 6, 1, '2025-11-29 16:52:12', '2025-12-20 16:52:13', '2025-12-02 06:36:23', 'returned'),
(122, 6, 1, '2025-12-02 06:36:39', '2025-12-23 06:36:40', '2025-12-02 07:26:26', 'returned'),
(123, 6, 1, '2025-12-02 07:26:41', '2025-12-23 07:26:42', '2025-12-05 07:45:29', 'returned'),
(124, 7, 1, '2025-12-02 14:57:14', '2025-12-23 14:57:15', '2025-12-04 10:19:23', 'returned'),
(125, 7, 2, '2025-12-04 10:32:14', '2025-12-25 10:32:14', '2025-12-04 10:32:17', 'returned'),
(126, 7, 1, '2025-12-04 10:40:15', '2025-12-25 10:40:15', '2025-12-04 10:40:18', 'returned'),
(127, 7, 1, '2025-12-04 10:40:21', '2025-12-25 10:40:22', '2025-12-04 10:41:17', 'returned'),
(128, 7, 1, '2025-12-04 10:41:35', '2025-12-25 10:41:35', '2025-12-04 10:41:37', 'returned'),
(129, 7, 1, '2025-12-04 10:41:40', '2025-12-25 10:41:40', '2025-12-05 07:03:00', 'returned'),
(130, 7, 1, '2025-12-05 07:40:20', '2025-12-26 07:40:21', '2025-12-05 07:41:06', 'returned'),
(131, 7, 1, '2025-12-05 07:45:13', '2025-12-26 07:45:14', '2025-12-05 08:55:04', 'returned'),
(132, 6, 1, '2025-12-05 07:45:39', '2025-12-26 07:45:39', '2025-12-05 08:15:50', 'returned'),
(133, 6, 1, '2025-12-05 08:16:20', '2025-12-26 08:16:21', '2025-12-05 08:17:51', 'returned'),
(134, 6, 1, '2025-12-05 08:23:38', '2025-12-26 08:23:39', '2025-12-05 08:23:42', 'returned'),
(135, 6, 1, '2025-12-05 08:23:45', '2025-12-26 08:23:46', '2025-12-05 08:23:49', 'returned'),
(136, 6, 1, '2025-12-05 08:23:57', '2025-12-26 08:23:57', '2025-12-05 12:28:45', 'returned'),
(137, 7, 1, '2025-12-05 08:55:18', '2025-12-26 08:55:19', '2025-12-05 08:55:21', 'returned'),
(138, 7, 1, '2025-12-05 08:55:24', '2025-12-26 08:55:24', '2025-12-05 08:55:25', 'returned'),
(139, 7, 1, '2025-12-05 09:01:55', '2025-12-26 09:01:56', '2025-12-05 12:08:06', 'returned'),
(140, 8, 1, '2025-12-05 11:14:37', '2025-12-26 11:14:38', '2025-12-05 11:14:54', 'returned'),
(141, 8, 1, '2025-12-05 11:16:38', '2025-12-26 11:16:39', '2025-12-05 11:16:42', 'returned'),
(142, 8, 1, '2025-12-05 11:36:50', '2025-12-26 11:36:51', '2025-12-05 11:37:15', 'returned'),
(143, 12, 1, '2025-12-05 12:28:01', '2025-12-26 12:28:01', '2025-12-05 12:31:25', 'returned'),
(144, 6, 1, '2025-12-05 12:28:58', '2025-12-26 12:28:58', '2025-12-05 13:18:30', 'returned'),
(145, 7, 1, '2025-12-05 12:30:26', '2025-12-26 12:30:26', '2025-12-05 12:42:24', 'returned'),
(146, 9, 1, '2025-12-05 12:33:35', '2025-12-26 12:33:35', '2025-12-05 12:34:29', 'returned'),
(147, 8, 1, '2025-12-05 12:34:38', '2025-12-26 12:34:39', '2025-12-05 12:34:41', 'returned'),
(148, 10, 1, '2025-12-05 12:34:52', '2025-12-26 12:34:52', '2025-12-05 12:34:54', 'returned'),
(149, 10, 1, '2025-12-05 12:35:03', '2025-12-26 12:35:03', '2025-12-05 12:35:26', 'returned'),
(150, 7, 1, '2025-12-05 12:42:57', '2025-12-26 12:42:57', '2025-12-05 12:42:59', 'returned'),
(151, 15, 1, '2025-12-05 12:44:05', '2025-12-26 12:44:05', '2025-12-05 12:44:09', 'returned'),
(152, 7, 1, '2025-12-05 13:02:21', '2025-12-26 13:02:21', '2025-12-05 13:02:27', 'returned'),
(153, 7, 1, '2025-12-05 13:02:49', '2025-12-26 13:02:50', '2025-12-14 15:28:43', 'returned'),
(154, 6, 2, '2025-12-05 13:18:53', '2025-12-26 13:18:54', '2025-12-05 13:19:29', 'returned'),
(155, 16, 2, '2025-12-06 03:11:39', '2025-12-27 03:11:40', '2025-12-09 10:21:42', 'returned'),
(156, 6, 1, '2025-12-06 03:13:33', '2025-12-27 03:13:33', '2025-12-10 12:52:41', 'returned'),
(157, 8, 4, '2025-12-08 16:38:29', '2025-12-29 16:38:30', '2025-12-08 16:38:43', 'returned'),
(158, 8, 4, '2025-12-08 16:38:50', '2025-12-29 16:38:50', '2025-12-09 09:48:02', 'returned'),
(159, 13, 4, '2025-12-09 09:49:31', '2025-12-30 09:49:31', '2025-12-09 09:49:34', 'returned'),
(160, 12, 2, '2025-12-09 09:49:47', '2025-12-30 09:49:47', '2025-12-09 09:50:03', 'returned'),
(161, 12, 2, '2025-12-09 10:13:07', '2025-12-30 10:13:08', '2025-12-09 10:17:54', 'returned'),
(162, 12, 2, '2025-12-09 10:20:47', '2025-12-30 10:20:48', '2025-12-09 10:21:36', 'returned'),
(163, 12, 2, '2025-12-09 10:24:38', '2025-12-30 10:24:38', '2025-12-09 10:27:09', 'returned'),
(164, 12, 2, '2025-12-09 10:27:26', '2025-12-30 10:27:27', '2025-12-10 14:23:48', 'returned'),
(165, 8, 4, '2025-12-09 10:43:10', '2025-12-30 10:43:10', '2025-12-09 10:43:19', 'returned'),
(166, 8, 2, '2025-12-09 11:46:27', '2025-12-30 11:46:27', '2025-12-09 11:46:47', 'returned'),
(167, 8, 2, '2025-12-09 11:52:46', '2025-12-30 11:52:46', '2025-12-09 11:53:52', 'returned'),
(168, 11, 2, '2025-12-09 12:30:57', '2025-12-30 12:30:58', '2025-12-10 14:23:30', 'returned'),
(169, 6, 2, '2025-12-10 12:54:53', '2025-12-31 12:54:54', '2025-12-10 12:55:01', 'returned'),
(170, 6, 4, '2025-12-10 12:55:59', '2025-12-31 12:55:59', '2025-12-10 13:31:16', 'returned'),
(171, 6, 4, '2025-12-10 13:31:43', '2025-12-31 13:31:44', '2025-12-10 14:25:11', 'returned'),
(172, 6, 4, '2025-12-10 14:25:32', '2025-12-31 14:25:32', '2025-12-10 14:25:45', 'returned'),
(173, 6, 4, '2025-12-10 14:31:03', '2025-12-31 14:31:03', '2025-12-10 14:31:31', 'returned'),
(174, 8, 4, '2025-12-10 14:40:24', '2025-12-31 14:40:25', '2025-12-12 08:38:48', 'returned'),
(175, 6, 2, '2025-12-11 06:43:09', '2026-01-01 06:43:09', '2025-12-16 13:14:39', 'returned'),
(176, 17, 2, '2025-12-12 09:05:07', '2026-01-02 09:05:08', '2025-12-12 09:05:28', 'returned'),
(177, 9, 2, '2025-12-14 15:16:17', '2026-01-04 15:16:17', '2025-12-14 15:22:35', 'returned'),
(178, 7, 1, '2025-12-14 15:29:27', '2026-01-04 15:29:27', '2025-12-14 15:31:00', 'returned'),
(179, 8, 1, '2025-12-14 15:33:58', '2026-01-04 15:33:58', '2025-12-14 15:34:41', 'returned'),
(180, 16, 20, '2025-12-14 23:48:49', '2026-01-04 23:48:49', '2025-12-14 23:49:00', 'returned'),
(181, 6, 2, '2025-12-16 13:15:08', '2026-01-06 13:15:09', '2025-12-16 13:27:11', 'returned'),
(182, 8, 1, '2025-12-16 13:24:15', '2026-01-06 13:24:15', '2026-01-29 00:43:34', 'expired'),
(183, 6, 2, '2025-12-16 13:27:47', '2026-01-06 13:27:47', '2025-12-24 11:38:29', 'returned'),
(184, 12, 2, '2025-12-16 13:57:54', '2026-01-06 13:57:54', '2025-12-16 13:58:12', 'returned'),
(185, 7, 2, '2025-12-16 14:19:08', '2026-01-06 14:19:08', '2025-12-24 03:27:56', 'returned'),
(186, 7, 2, '2025-12-24 05:47:33', '2026-01-14 05:47:33', '2025-12-26 12:33:07', 'returned'),
(187, 6, 2, '2025-12-24 11:39:23', '2026-01-14 11:39:23', '2025-12-27 08:02:47', 'returned'),
(188, 11, 2, '2025-12-24 12:31:22', '2026-01-14 12:31:22', '2025-12-26 12:32:59', 'returned'),
(189, 12, 1, '2025-12-24 13:42:54', '2026-01-14 13:42:55', '2025-12-24 13:43:41', 'returned'),
(190, 12, 2, '2025-12-24 14:56:05', '2026-01-14 14:56:05', '2026-01-29 00:43:34', 'expired'),
(191, 7, 2, '2025-12-27 08:00:19', '2026-01-17 08:00:20', '2025-12-27 08:02:12', 'returned'),
(192, 6, 2, '2025-12-27 08:03:11', '2026-01-17 08:03:12', '2026-01-26 16:06:37', 'returned'),
(193, 7, 4, '2025-12-27 08:04:39', '2026-01-17 08:04:40', '2025-12-27 08:05:24', 'returned'),
(194, 6, 2, '2026-01-26 16:06:53', '2026-02-16 16:06:54', '2026-01-29 01:08:44', 'returned'),
(195, 6, 2, '2026-01-29 01:08:50', '2026-02-19 01:08:50', '2026-02-27 12:31:05', 'expired'),
(196, 6, 2, '2026-02-27 12:41:12', '2026-03-20 12:41:12', '2026-03-21 02:20:57', 'expired'),
(197, 6, 2, '2026-03-21 02:27:02', '2026-04-11 01:27:02', '2026-03-24 11:34:56', 'returned'),
(198, 18, 2, '2026-03-23 12:36:32', '2026-04-13 11:36:32', '2026-04-14 22:22:04', 'expired'),
(199, 7, 2, '2026-03-24 00:46:21', '2026-04-13 23:46:21', '2026-04-14 22:22:04', 'expired'),
(200, 6, 2, '2026-03-24 11:50:15', '2026-04-14 10:50:15', '2026-04-14 22:22:03', 'expired'),
(201, 6, 2, '2026-04-14 22:23:17', '2026-05-05 21:23:18', '2026-05-12 22:17:43', 'expired'),
(202, 18, 2, '2026-04-14 22:31:21', '2026-05-06 00:31:18', '2026-05-12 22:17:45', 'expired'),
(203, 6, 2, '2026-05-19 12:57:53', '2026-06-09 11:57:51', NULL, 'active'),
(204, 18, 2, '2026-06-05 08:20:22', '2026-06-26 07:20:23', NULL, 'active');

-- --------------------------------------------------------

--
-- Table structure for table `sponsors`
--

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

CREATE TABLE `system_settings` (
  `setting_key` varchar(50) NOT NULL,
  `setting_value` varchar(255) NOT NULL,
  `description` text DEFAULT NULL
);

--
-- Dumping data for table `system_settings`
--

INSERT INTO `system_settings` (`setting_key`, `setting_value`, `description`) VALUES
('sponsorship_rate_amount', '1000', 'Cost for one batch of sponsorship'),
('sponsorship_rate_copies', '10', 'Number of book copies added per batch');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` INTEGER NOT NULL,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
);

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `email`, `password`, `name`, `created_at`) VALUES
(1, 'semirsultan3@gmail.com', '$2a$10$0xLECVkKIYG2z/qvvrF85Ou68dndkbjMD2/hxpmi3h/YSu123oy0W', 'semirsultan', '2025-10-16 12:40:14'),
(2, 's@gmail.com', '$2a$10$iIm/cfQ47c5iiRQ50U5bQe.Rk9W4R2ty.Za9YWWqr0zLLZW.9cfVq', 's', '2025-10-20 00:09:17'),
(3, 'f@gmail.com', '$2a$10$UcyfnysSbPZolDMiM.wxne5SBz8orWBXtu.oq0SEsRLQWumfkwgka', 'f', '2025-11-08 22:09:48'),
(4, 'h@gmail.com', '$2a$10$i6DmMppXBfBqLHWiCZHItO.KHeAA4TZrLE/vBkODJ.5wNBcXMjki.', 'h', '2025-11-18 03:15:24'),
(5, 'r@gmail.com', '$2a$10$2/FPwk8nBeHJhi4Jt/5rfecb5OoSFy7l7Y1Wb6Qj0OntKjMlJI8zi', 'r', '2025-12-02 15:03:32'),
(6, 'g@gmail.com', '$2a$10$le0YfHlSttKCmf6INZprO.SK8if0/0HhsWeL3kLkWyf3.GgY.D7J2', 'gg', '2025-12-10 14:41:28'),
(7, 'ddd@gmail.com', '$2a$10$RuWW6UiL5fSK3szwthdeduPtmRyAoemdmEMJ5uMagiC0VlACs51eC', 'ddd', '2025-12-11 16:19:39'),
(8, 'et@gmail.com', '$2a$10$mDUn6isM6S0YM5pd.Fwd0OBZC4tsCNTOUaHYDxIeejpbXJOr8IVOe', 'ET', '2025-12-11 16:29:40'),
(9, 'yui@gmail.com', '$2a$10$OLNBBnv2tKNdj56KNNmfQeqzs5RS22eMX8Mz9Yp2YeOj6e3h37D6.', 'yui', '2025-12-11 16:38:01'),
(10, 'er@gmail.com', '$2a$10$eHWFAHmNXN5i/F2W8lN0sulCLFf8LoszgjX/XSfYzNErUBUUHoa9e', 'er', '2025-12-12 07:56:56'),
(11, 'rt@gmail.com', '$2a$10$.lAYqhLzcLRU8uiwdksMfetv0uA0c5H5rzS0iJpNG4eoWAc87Fe3y', 'rt', '2025-12-12 08:05:52'),
(12, 'fr@gmail.com', '$2a$10$0TNP5hLrfgJ1sisGRJeq3uqRJYYtgQh.X/5ZFZPkUayBIoyRw0Lxi', 'FR', '2025-12-12 08:07:42'),
(13, 'gh@gmail.com', '$2a$10$V1FAVgF6LYAs7Nl8W62bjeZO.XzH.DVSGTdwO6Ty.DMoBxmnbbUUS', 'gh', '2025-12-12 08:09:57'),
(14, 'fg@gmail.com', '$2a$10$K0cTQW2hzP1Yh6Lbs5mC8.hVxTRAlXL9hxXoK/J9EFvNna/Bp.cFS', 'FG', '2025-12-12 08:13:26'),
(15, 'gy@gmail.com', '$2a$10$jLyeRta8oSuIGHsyNAyxxOJjzQyRsLkuE29M48UkWodn9whCgOnt.', 'GY', '2025-12-12 08:21:46'),
(16, 'e@gmail.com', '$2a$10$lmFJuAqZk7PXZRsiOlVb3OhGv70u2ubAd2qLT5jVdIe6UjBaOi4Xi', 'Eee', '2025-12-13 10:50:54'),
(17, 'YI@gmail.com', '$2a$10$W2tBjelmnMnAEeWlcPpouuxF.xEhA7EA5rmCDCrmXYvbZhoLC7UTa', 'YI', '2025-12-13 10:52:40'),
(18, 'ryr@gmail.com', '$2a$10$Q4a0AGhMJWVA7vMwiQNcVOnAoHgH9EyJT3saqLvHtoEoeFqjVlWEu', 'RYT', '2025-12-13 11:01:35'),
(19, 'vg@gmail.com', '$2a$10$k88b5dYTbYyTnORycIRa9uuG5J2vzfG/Mll2aPLrMoqA9rMOIv77W', 'vg', '2025-12-14 22:42:13'),
(20, 'ayele@gmail.com', '$2a$10$TLy7pkj/Y22u/97tMFc8t.9bW9UmwDOEoNULO7WdmNRa4EJ9EitW.', 'ayele', '2025-12-14 23:47:05'),
(21, 'mac@gmail.com', '$2a$10$PxbgyNuIc7qZsvfLwixcGOPXODLt4BnNKaNIk5p6XHZeznrThjVmW', 'mac', '2025-12-26 12:42:24'),
(22, 'tt@gmail.com', '$2a$10$W.Q5UpQkyQby7pwnZSACmOdYLpDI7yD8pLTx182pF8XN8s4EN.6aa', 'tt', '2025-12-27 07:46:50'),
(23, 'duo@gmail.com', '$2a$10$NKCML9v1hcG.ZD9G836a5eFJw/7hr5HWnrn02rk5QSMYqm9LAGHce', 'duo', '2026-03-24 05:37:10'),
(24, 'ggo@gmail.com', '$2a$10$r2/tRoRm62Zd6GMnXIBIgOE9e2V9JbuxPnevVIA4Wo//uSGsSbxdu', 'ggo', '2026-04-21 09:58:05');

-- --------------------------------------------------------

--
-- Table structure for table `user_devices`
--

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






