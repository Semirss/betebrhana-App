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
-- Table structure for table `encryption_keys`
--

DROP TABLE IF EXISTS `encryption_keys`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `encryption_keys` (
  `id` varchar(255) NOT NULL,
  `user_id` int NOT NULL,
  `book_id` int NOT NULL,
  `key_data` text NOT NULL,
  `device_fingerprint` varchar(255) NOT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `expires_at` datetime NOT NULL,
  `used_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`),
  KEY `book_id` (`book_id`),
  KEY `idx_expires` (`expires_at`),
  CONSTRAINT `encryption_keys_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `encryption_keys_ibfk_2` FOREIGN KEY (`book_id`) REFERENCES `books` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `encryption_keys`
--

LOCK TABLES `encryption_keys` WRITE;
/*!40000 ALTER TABLE `encryption_keys` DISABLE KEYS */;
INSERT INTO `encryption_keys` VALUES ('6a6605c3-00b4-4480-b70a-6d008a8bc328',1,6,'ea1e1ea771cd71fc7fc1bd399e0e0b548fec93bc0b41e20ec168f9d567c1f088','7db5fc750cbbf80c04150867e13af1f6e1ab694a03d95d1be3920e954439ac7f','2025-10-30 16:04:08','2025-10-30 17:04:08','2025-10-30 16:04:08'),('e4c41d22-8831-4ef1-b47e-68d0cffb0e98',1,6,'04214da90b2acc3c279356a975d4272c36ccf8bcea1fd4adeecb47b247ac97dd','7db5fc750cbbf80c04150867e13af1f6e1ab694a03d95d1be3920e954439ac7f','2025-10-30 16:03:51','2025-10-30 17:03:51','2025-10-30 16:03:51'),('ee57961b-8da2-476d-ba06-1bd2d8f8fa23',1,6,'1e3f5e9d2b7638ea4973f0dfa2364342a89f412dc5d9d44fb407455453e2a31f','7db5fc750cbbf80c04150867e13af1f6e1ab694a03d95d1be3920e954439ac7f','2025-10-30 16:02:55','2025-10-30 17:02:55','2025-10-30 16:02:55');
/*!40000 ALTER TABLE `encryption_keys` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-01-28 18:02:29
