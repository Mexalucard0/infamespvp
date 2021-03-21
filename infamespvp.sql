-- --------------------------------------------------------
-- Host:                         127.0.0.1
-- Server version:               10.4.17-MariaDB - mariadb.org binary distribution
-- Server OS:                    Win64
-- HeidiSQL Version:             11.2.0.6213
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


-- Dumping database structure for fishydev3
CREATE DATABASE IF NOT EXISTS `fishydev3` /*!40100 DEFAULT CHARACTER SET utf8mb4 */;
USE `fishydev3`;

-- Dumping structure for table fishydev3.players
CREATE TABLE IF NOT EXISTS `players` (
  `PlayerID` varchar(50) NOT NULL,
  `PlayerName` varchar(50) NOT NULL,
  `DiscordID` varchar(50) DEFAULT NULL,
  `TimePlayed` int(10) unsigned NOT NULL DEFAULT 0,
  `Banned` tinyint(1) NOT NULL DEFAULT 0,
  `BanExpiresDate` int(11) DEFAULT NULL,
  `Moderator` int(10) unsigned DEFAULT NULL,
  `PatreonTier` int(10) unsigned DEFAULT NULL,
  `LoginTime` int(10) unsigned DEFAULT NULL,
  `Cash` int(10) unsigned NOT NULL DEFAULT 50000,
  `Experience` int(10) unsigned NOT NULL DEFAULT 0,
  `Prestige` int(10) unsigned NOT NULL DEFAULT 0,
  `Kills` int(10) unsigned NOT NULL DEFAULT 0,
  `Deaths` int(10) unsigned NOT NULL DEFAULT 0,
  `MoneyWasted` int(10) unsigned NOT NULL DEFAULT 0,
  `Headshots` int(10) unsigned NOT NULL DEFAULT 0,
  `VehicleKills` int(10) unsigned NOT NULL DEFAULT 0,
  `MaxKillstreak` int(10) unsigned NOT NULL DEFAULT 0,
  `MissionsDone` int(10) unsigned NOT NULL DEFAULT 0,
  `EventsWon` int(10) unsigned NOT NULL DEFAULT 0,
  `LongestKillDistance` int(10) unsigned NOT NULL DEFAULT 0,
  `SkinModel` mediumtext DEFAULT NULL,
  `Weapons` mediumtext DEFAULT NULL,
  `WeaponStats` mediumtext DEFAULT NULL,
  `Garages` mediumtext DEFAULT NULL,
  `Vehicles` longtext DEFAULT NULL,
  `DrugBusiness` mediumtext DEFAULT NULL,
  `Records` mediumtext DEFAULT NULL,
  `Settings` mediumtext DEFAULT NULL,
  PRIMARY KEY (`PlayerID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Dumping data for table fishydev3.players: ~1 rows (approximately)
/*!40000 ALTER TABLE `players` DISABLE KEYS */;
/*!40000 ALTER TABLE `players` ENABLE KEYS */;

-- Dumping structure for table fishydev3.survivalrecords
CREATE TABLE IF NOT EXISTS `survivalrecords` (
  `SurvivalID` varchar(50) NOT NULL,
  `PlayerName` varchar(50) NOT NULL,
  `Waves` int(10) unsigned NOT NULL,
  PRIMARY KEY (`SurvivalID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Dumping data for table fishydev3.survivalrecords: ~0 rows (approximately)
/*!40000 ALTER TABLE `survivalrecords` DISABLE KEYS */;
/*!40000 ALTER TABLE `survivalrecords` ENABLE KEYS */;

-- Dumping structure for table fishydev3.timetrialrecords
CREATE TABLE IF NOT EXISTS `timetrialrecords` (
  `TrialID` varchar(50) NOT NULL,
  `PlayerName` varchar(50) NOT NULL,
  `Time` int(10) unsigned NOT NULL,
  PRIMARY KEY (`TrialID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Dumping data for table fishydev3.timetrialrecords: ~0 rows (approximately)
/*!40000 ALTER TABLE `timetrialrecords` DISABLE KEYS */;
/*!40000 ALTER TABLE `timetrialrecords` ENABLE KEYS */;

/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
