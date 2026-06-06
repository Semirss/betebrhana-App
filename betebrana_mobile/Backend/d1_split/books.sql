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
