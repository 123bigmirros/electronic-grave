-- MySQL dump 10.13  Distrib 9.0.1, for macos14.7 (arm64)
--
-- Host: localhost    Database: grave
-- ------------------------------------------------------
-- Server version	9.0.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `CanvasDTO`
--

DROP TABLE IF EXISTS `CanvasDTO`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `CanvasDTO` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `uId` bigint DEFAULT NULL,
  `title` text,
  `isPublic` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9971 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `CanvasDTO`
--

LOCK TABLES `CanvasDTO` WRITE;
/*!40000 ALTER TABLE `CanvasDTO` DISABLE KEYS */;
/*!40000 ALTER TABLE `CanvasDTO` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `heritage`
--

DROP TABLE IF EXISTS `heritage`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `heritage` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `pid` bigint DEFAULT NULL,
  `public_time` datetime DEFAULT NULL COMMENT '公开时间',
  `left_location` int DEFAULT NULL,
  `top_location` int DEFAULT NULL,
  `width_location` int DEFAULT NULL,
  `height_location` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`pid`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='遗产组件表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `heritage`
--

LOCK TABLES `heritage` WRITE;
/*!40000 ALTER TABLE `heritage` DISABLE KEYS */;
INSERT INTO `heritage` VALUES (1,1,'1970-01-01 08:00:00',487,139,300,200),(2,9927,NULL,378,411,300,200),(3,9928,NULL,378,411,300,200),(4,9930,NULL,639,251,300,200),(5,9931,NULL,639,251,300,200),(6,9935,NULL,780,240,300,200),(7,9935,NULL,417,136,300,200),(8,9936,NULL,780,240,300,200),(9,9936,NULL,417,136,300,200);
/*!40000 ALTER TABLE `heritage` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `heritage_item`
--

DROP TABLE IF EXISTS `heritage_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `heritage_item` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `heritage_id` bigint NOT NULL COMMENT '关联的遗产组件ID',
  `content` text NOT NULL COMMENT '遗产内容',
  `is_private` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否为"有缘者得"',
  `user_id` bigint DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `idx_heritage_id` (`heritage_id`),
  CONSTRAINT `heritage_item_ibfk_1` FOREIGN KEY (`heritage_id`) REFERENCES `heritage` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='遗产条目表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `heritage_item`
--

LOCK TABLES `heritage_item` WRITE;
/*!40000 ALTER TABLE `heritage_item` DISABLE KEYS */;
/*!40000 ALTER TABLE `heritage_item` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ImageBox`
--

DROP TABLE IF EXISTS `ImageBox`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ImageBox` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `pid` bigint DEFAULT NULL,
  `imageUrl` varchar(255) DEFAULT NULL,
  `left_location` int DEFAULT NULL,
  `top_location` int DEFAULT NULL,
  `width_location` int DEFAULT NULL,
  `height_location` int DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ImageBox`
--

LOCK TABLES `ImageBox` WRITE;
/*!40000 ALTER TABLE `ImageBox` DISABLE KEYS */;
INSERT INTO `ImageBox` VALUES (10,1,'https://via.placeholder.com/150',478,223,150,150);
/*!40000 ALTER TABLE `ImageBox` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `markdown`
--

DROP TABLE IF EXISTS `markdown`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `markdown` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `pid` bigint NOT NULL COMMENT '用户ID',
  `content` text COMMENT 'markdown内容',
  `left_location` int DEFAULT NULL,
  `top_location` int DEFAULT NULL,
  `width_location` int DEFAULT NULL,
  `height_location` int DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Markdown组件表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `markdown`
--

LOCK TABLES `markdown` WRITE;
/*!40000 ALTER TABLE `markdown` DISABLE KEYS */;
INSERT INTO `markdown` VALUES (2,1,'# 新建Markdown\n请输入内容',504,160,400,300),(3,1,'# 新建Markdown\n请输入内容',561,134,400,300),(4,1,'# 新建Markdown\n请输入内容',815,119,400,300),(5,1,'# 新建Markdown\n请输入内容',545,140,400,300);
/*!40000 ALTER TABLE `markdown` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `TextBox`
--

DROP TABLE IF EXISTS `TextBox`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `TextBox` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `pid` bigint DEFAULT NULL,
  `content` text,
  `left_location` int DEFAULT NULL,
  `top_location` int DEFAULT NULL,
  `width_location` int DEFAULT NULL,
  `height_location` int DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=37 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `TextBox`
--

LOCK TABLES `TextBox` WRITE;
/*!40000 ALTER TABLE `TextBox` DISABLE KEYS */;
INSERT INTO `TextBox` VALUES (10,1,'这是一个文本框',1080,162,200,50),(11,1,'这是一个文本框',495,226,200,50),(12,1,'这是一个文本框',602,203,200,50),(13,1,'这是一个文本框',520,54,200,50);
/*!40000 ALTER TABLE `TextBox` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user`
--

DROP TABLE IF EXISTS `user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user` (
  `id` bigint NOT NULL AUTO_INCREMENT COMMENT '用户ID',
  `username` varchar(50) NOT NULL COMMENT '用户名',
  `password` varchar(100) NOT NULL COMMENT '密码',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_username` (`username`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='用户表';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user`
--

LOCK TABLES `user` WRITE;
/*!40000 ALTER TABLE `user` DISABLE KEYS */;
INSERT INTO `user` VALUES (1,'root','root');
/*!40000 ALTER TABLE `user` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-02-26 21:32:56
