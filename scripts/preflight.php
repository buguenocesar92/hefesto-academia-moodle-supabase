<?php
function fail(string $message): never { fwrite(STDERR, $message . PHP_EOL); exit(1); }
foreach (['pgsql','intl','zip','gd','soap','mbstring','sodium','curl','xml'] as $ext) {
    if (!extension_loaded($ext)) fail('Falta extension: ' . $ext);
}
function quoted(string $v): string { return "'" . str_replace(["\\", "'"], ["\\\\", "\\'"], $v) . "'"; }
$parts = [];
foreach (['host'=>'DB_HOST','dbname'=>'DB_NAME','user'=>'DB_USER','password'=>'DB_PASSWORD'] as $key=>$env) {
    $value = getenv($env);
    if (!$value || str_contains($value, 'REEMPLAZAR')) fail('Falta configurar: ' . $env);
    $parts[] = $key . '=' . quoted($value);
}
$ssl = getenv('DB_SSL') ?: 'require';
if (!in_array($ssl, ['require','verify-full'], true)) fail('SSL no permitido');
$conn = @pg_connect(implode(' ', $parts) . ' port=5432 connect_timeout=15 sslmode=' . $ssl);
if (!$conn) fail('No se pudo conectar. Revisar host directo, red, CA y credenciales en servidor.');
$version = (int)pg_fetch_result(pg_query($conn, 'SHOW server_version_num'), 0, 0);
if ($version < 170000) fail('Moodle 5.3 requiere PostgreSQL 17 o superior.');
$q = pg_query($conn, "SELECT has_schema_privilege(current_user, 'moodle', 'USAGE') AND has_schema_privilege(current_user, 'moodle', 'CREATE')");
if (!$q || pg_fetch_result($q,0,0) !== 't') fail('Faltan permisos del esquema moodle.');
pg_query($conn, 'SET search_path TO moodle');
if (!pg_query($conn, 'BEGIN') || !pg_query($conn, 'CREATE TABLE hefesto_preflight_check (id integer)')) fail('No se pudo crear una tabla en moodle');
pg_query($conn, 'ROLLBACK');
echo "OK: extensiones, PostgreSQL >=17, conexion SSL y escritura en esquema moodle.\n";
