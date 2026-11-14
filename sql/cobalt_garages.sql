CREATE TABLE IF NOT EXISTS `garages` (
  `id` VARCHAR(64) NOT NULL,
  `label` VARCHAR(100) NOT NULL,
  `type` ENUM('car', 'boat', 'air', 'job', 'gang', 'house', 'impound') NOT NULL DEFAULT 'car',
  `enabled` TINYINT(1) NOT NULL DEFAULT 1,
  `data` JSON NOT NULL,
  `updated_by` VARCHAR(100) DEFAULT NULL,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
