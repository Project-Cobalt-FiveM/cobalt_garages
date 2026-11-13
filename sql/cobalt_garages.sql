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

CREATE TABLE IF NOT EXISTS `garage_vehicles` (
  `plate` VARCHAR(15) NOT NULL,
  `vehicle_type` VARCHAR(16) NOT NULL DEFAULT 'automobile',
  `class` TINYINT UNSIGNED DEFAULT NULL,
  `parked_at` DATETIME DEFAULT NULL,
  `impounded_at` DATETIME DEFAULT NULL,
  `impound_reason` VARCHAR(255) DEFAULT NULL,
  `impounded_by` VARCHAR(100) DEFAULT NULL,
  `hold_until` DATETIME DEFAULT NULL,
  PRIMARY KEY (`plate`),
  CONSTRAINT `garage_vehicles_plate_fk` FOREIGN KEY (`plate`) REFERENCES `player_vehicles` (`plate`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
