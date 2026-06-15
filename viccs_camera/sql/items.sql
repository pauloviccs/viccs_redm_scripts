-- ==========================================================
-- viccs_camera | SQL para registrar o item no banco de dados
-- ==========================================================
-- Execute este SQL no seu banco de dados MySQL/MariaDB
-- A tabela 'items' já existe no VORP Inventory
-- ==========================================================

INSERT INTO `items` (`item`, `label`, `limit`, `can_remove`, `type`, `usable`, `desc`)
VALUES ('camera', 'Câmera Fotográfica', 1, 1, 'item_standard', 1, 'Uma câmera fotográfica de época. Posicione-a no mundo e tire fotos incríveis!')
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`), `desc` = VALUES(`desc`);
