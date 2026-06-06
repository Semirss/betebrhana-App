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
