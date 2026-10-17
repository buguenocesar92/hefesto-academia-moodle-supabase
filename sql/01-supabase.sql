-- Ejecutar en SQL Editor de un proyecto Supabase dedicado, como postgres.
-- Reemplazar el texto password por uno aleatorio (32+ caracteres) ANTES de ejecutar.
-- No guardar la version con credenciales en Git ni compartirla.
BEGIN;
DO $$
DECLARE chosen_password text := 'REEMPLAZAR_PASSWORD_LARGO_UNICO';
BEGIN
 IF chosen_password LIKE 'REEMPLAZAR%' OR length(chosen_password)<32 THEN
   RAISE EXCEPTION 'Configura primero password aleatorio de al menos 32 caracteres';
 END IF;
 IF EXISTS (SELECT FROM pg_roles WHERE rolname='moodle_app') THEN
   RAISE EXCEPTION 'moodle_app ya existe; no se alteraron permisos ni password';
 END IF;
 EXECUTE format('CREATE ROLE moodle_app LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE PASSWORD %L', chosen_password);
END $$;
CREATE SCHEMA moodle AUTHORIZATION moodle_app;
GRANT CONNECT ON DATABASE postgres TO moodle_app;
REVOKE ALL ON SCHEMA moodle FROM PUBLIC, anon, authenticated;
ALTER ROLE moodle_app SET search_path = moodle;
ALTER ROLE moodle_app SET client_encoding = 'UTF8';
ALTER ROLE moodle_app SET standard_conforming_strings = on;
COMMIT;
-- NO agregar moodle a esquemas expuestos por Data API.
