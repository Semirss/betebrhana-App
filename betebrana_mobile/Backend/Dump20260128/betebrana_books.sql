-- MySQL dump 10.13  Distrib 8.0.43, for Win64 (x86_64)
--
-- Host: localhost    Database: betebrana
-- ------------------------------------------------------
-- Server version	9.4.0

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `books`
--

DROP TABLE IF EXISTS `books`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `books` (
  `id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL,
  `author` varchar(255) NOT NULL,
  `description` text,
  `total_copies` int DEFAULT '1',
  `available_copies` int DEFAULT '1',
  `file_path` varchar(500) DEFAULT NULL,
  `file_type` enum('pdf','doc','docx','txt') DEFAULT NULL,
  `file_size` int DEFAULT NULL,
  `cover_image` varchar(500) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `books`
--

LOCK TABLES `books` WRITE;
/*!40000 ALTER TABLE `books` DISABLE KEYS */;
INSERT INTO `books` VALUES (6,'ጦቢያ (Tobiya)','አፈወርቅ ገብረኢየሱስ ','በመጀመሪያ 1900 ዓ.ም. በሮማ ከተማ ታተመ፡፡',1,0,'/documents/document-1760881771279-235542173.txt','txt',29350,'/covers/hijaced.jpg','2025-10-19 13:49:31'),(7,'አ(ABETSELOM)',' ተሰማ ብርሃኑ','በመጀመሪያ 1900 ዓ.ም. በሮማ ከተማ ታተመ፡፡በመጀመሪያ 1900 ዓ.ም. በሮማ ከተማ ታተመ፡፡በመጀመሪያ 1900 ዓ.ም. በሮማ ከተማ ታተመ፡፡በመጀመሪያ 1900 ዓ.ም. በሮማ ከተማ ታተመ፡፡በመጀመሪያ 1900 ዓ.ም. በሮማ ከተማ ታተመ፡፡በመጀመሪያ 1900 ዓ.ም. በሮማ ከተማ ታተመ፡፡በመጀመሪያ 1900 ዓ.ም. በሮማ ከተማ ታተመ፡፡በመጀመሪያ 1900 ዓ.ም. በሮማ ከተማ ታተመ፡፡በመጀመሪያ 1900 ዓ.ም. በሮማ ከተማ ታተመ፡፡በመጀመሪያ 1900 ዓ.ም. በሮማ ከተማ ታተመ፡፡በመጀመሪያ 1900 ዓ.ም. በሮማ ከተማ ታተመ፡፡',1,1,'/documents/try.pdf','pdf',29350,'/covers/hijaced1.jpg','2025-10-19 13:49:31'),(8,'ፍቅር በአዲስ አበባ','ብርሃኑ ተሰማ','ምስል የሚሰጥ የፍቅር ታሪክ በአዲስ አበባ ውስጥ የሚደረግ እንቅስቃሴ',1,0,'/documents/love_in_addis.txt','txt',24500,'/covers/hijaced2.jpg','2025-12-05 07:00:00'),(9,'የኢትዮጵያ ታሪክ','ዶክተር ዘሪሁን ማሞ','ከጥንት እስከ ዘመናዊ የኢትዮጵያ ታሪክ ማጠቃለያ',1,1,'/documents/ethiopian_history.txt','txt',37800,'/covers/hijaced3.jpg','2025-12-05 07:05:00'),(10,'ልጆች ለልጆች','ሄለን ነጋሽ','ለልጆች የተጻፉ የሚያስቡ ታሪኮች እና ምክሮች',1,1,'/documents/children_stories.txt','txt',15600,'/covers/hijaced4.jpg','2025-12-05 07:10:00'),(11,'የገበሬ ህይወት','ጌታቸው ታደሰ','የኢትዮጵያ ገበሬ ቀንበር እና የህይወት ተጋድሎ',1,1,'/documents/farmer_life.txt','txt',28900,'/covers/hijaced5.jpg','2025-12-05 07:15:00'),(12,'የቃላት ጥበብ','ፍቅር መኮንን','የአማርኛ ቋንቋ ትክክለኛ አጠቃቀም እና የቃላት ስልት',1,0,'/documents/language_wisdom.txt','txt',31200,'/covers/hijaced6.jpg','2025-12-05 07:20:00'),(13,'አርቲስቶች ዓለም','ሙሉጌታ ላም','የኢትዮጵያ አርቲስቶች ህይወት እና ስራ',1,1,'/documents/artists_world.txt','txt',26700,'/covers/hijaced7.jpg','2025-12-05 07:25:00'),(14,'የቤተሰብ ግንኙነት','ደራስ ተክለሃይማኖት','ዘመናዊ የቤተሰብ ግንኙነት እና ህይወት ምክሮች',1,1,'/documents/family_relationship.txt','txt',30100,'/covers/hijaced8.jpg','2025-12-05 07:30:00'),(15,'ኢንተርኔት እና ማህበረሰብ','አብይ ሻምበል','ዘመናዊ ቴክኖሎጂ በኢትዮጵያ ማህበረሰብ ላይ ያለው ተጽዕኖ',1,1,'/documents/internet_society.txt','txt',32800,'/covers/hijaced9.jpg','2025-12-05 07:35:00'),(16,'የጤና መመሪያ','ዶክተር ሜሪ አባተ','መሰረታዊ የጤና ጥንቃቄዎች እና መከላከያ ዘዴዎች',1,1,'/documents/health_guide.txt','txt',25600,'/covers/hijaced10.jpg','2025-12-05 07:40:00'),(17,'የንግድ ስኬት','ሳሙኤል ገብረማርያም','አነስተኛ ንግድ ለመጀመር እና ለማስፋፋት የሚረዱ ምክሮች',1,1,'/documents/business_success.txt','txt',29400,'/covers/hijaced11.jpg','2025-12-05 07:45:00');
/*!40000 ALTER TABLE `books` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-01-28 18:02:28
