CREATE TABLE `system_settings` (
  `setting_key` varchar(50) NOT NULL PRIMARY KEY,
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
