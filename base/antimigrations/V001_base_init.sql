-- 1. Удаление таблиц (от независимых к родительским)
DROP TABLE IF EXISTS clearing.fin_doc CASCADE;
DROP TABLE IF EXISTS processing.status_history CASCADE;
DROP TABLE IF EXISTS processing.transaction CASCADE;
DROP TABLE IF EXISTS risk.accumulator CASCADE;
DROP TABLE IF EXISTS risk.limits CASCADE;
DROP TABLE IF EXISTS vault.token CASCADE;
DROP TABLE IF EXISTS vault.card CASCADE;
DROP TABLE IF EXISTS catalog.mcc CASCADE;
DROP TABLE IF EXISTS identity.users_roles CASCADE;
DROP TABLE IF EXISTS identity.user CASCADE;
DROP TABLE IF EXISTS identity.role CASCADE;
DROP TABLE IF EXISTS identity.organization CASCADE;

-- 2. Опционально: Удаление схем (обычно схемы оставляют, но если нужно вычистить полностью)
DROP SCHEMA IF EXISTS clearing CASCADE;
DROP SCHEMA IF EXISTS processing CASCADE;
DROP SCHEMA IF EXISTS risk CASCADE;
DROP SCHEMA IF EXISTS vault CASCADE;
DROP SCHEMA IF EXISTS catalog CASCADE;
DROP SCHEMA IF EXISTS identity CASCADE;
