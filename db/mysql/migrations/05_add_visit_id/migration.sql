-- AlterTable
ALTER TABLE `website_event` ADD COLUMN `visit_id` VARCHAR(36) NULL;

-- Original migration causes database error: FUNCTION db_name.BIN_TO_UUID does not exist
-- because MariaDB does not have BIN_TO_UUID function.
-- UPDATE `website_event` we
-- JOIN (SELECT DISTINCT
--         s.session_id,
--         s.visit_time,
--         BIN_TO_UUID(RANDOM_BYTES(16) & 0xffffffffffff0fff3fffffffffffffff | 0x00000000000040008000000000000000) uuid
--     FROM (SELECT DISTINCT session_id,
--             DATE_FORMAT(created_at, '%Y-%m-%d %H:00:00') visit_time
--         FROM `website_event`) s) a
--     ON we.session_id = a.session_id and DATE_FORMAT(we.created_at, '%Y-%m-%d %H:00:00') = a.visit_time
-- SET we.visit_id = a.uuid
-- WHERE we.visit_id IS NULL;

UPDATE website_event we
JOIN (
SELECT DISTINCT
s.session_id,
s.visit_time,
LOWER(CONCAT(
HEX(SUBSTR(MD5(RAND()), 1, 4)), '-',
HEX(SUBSTR(MD5(RAND()), 1, 2)), '-4',
SUBSTR(HEX(SUBSTR(MD5(RAND()), 1, 2)), 2, 3), '-',
CONCAT(HEX(FLOOR(ASCII(SUBSTR(MD5(RAND()), 1, 1)) / 64)+8),SUBSTR(HEX(SUBSTR(MD5(RAND()), 1, 2)), 2, 3)), '-',
HEX(SUBSTR(MD5(RAND()), 1, 6))
)) AS uuid
FROM (
SELECT DISTINCT session_id,
DATE_FORMAT(created_at, '%Y-%m-%d %H:00:00') visit_time
FROM website_event
) s
) a ON we.session_id = a.session_id AND DATE_FORMAT(we.created_at, '%Y-%m-%d %H:00:00') = a.visit_time
SET we.visit_id = a.uuid
WHERE we.visit_id IS NULL;

ALTER TABLE `website_event` MODIFY `visit_id` VARCHAR(36) NOT NULL;

-- CreateIndex
CREATE INDEX `website_event_visit_id_idx` ON `website_event`(`visit_id`);

-- CreateIndex
CREATE INDEX `website_event_website_id_visit_id_created_at_idx` ON `website_event`(`website_id`, `visit_id`, `created_at`);
