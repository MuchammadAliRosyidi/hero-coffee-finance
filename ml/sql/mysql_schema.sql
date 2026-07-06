CREATE DATABASE IF NOT EXISTS hero_coffee_finance
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE hero_coffee_finance;

CREATE TABLE IF NOT EXISTS transaction_items (
  id VARCHAR(64) NOT NULL,
  title VARCHAR(150) NOT NULL,
  category VARCHAR(80) NOT NULL,
  amount DECIMAL(14,2) NOT NULL DEFAULT 0,
  type ENUM('income', 'expense') NOT NULL DEFAULT 'expense',
  transaction_date VARCHAR(20) NOT NULL,
  created_at VARCHAR(40) NOT NULL,
  outlet_id VARCHAR(64) NOT NULL DEFAULT 'main',
  raw_payload JSON NULL,
  synced_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  INDEX idx_transaction_date (transaction_date),
  INDEX idx_outlet_id (outlet_id),
  INDEX idx_type (type),
  INDEX idx_category (category)
);

CREATE TABLE IF NOT EXISTS sync_logs (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  action VARCHAR(60) NOT NULL,
  message TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
);
