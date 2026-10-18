<?php
unset($CFG);
global $CFG;
$CFG = new stdClass();
function hefesto_env(string $key): string {
    $value = getenv($key);
    if ($value === false || $value === '' || str_contains($value, 'REEMPLAZAR')) {
        throw new RuntimeException('Falta configurar: ' . $key);
    }
    return $value;
}
$CFG->dbtype = 'pgsql';
$CFG->dblibrary = 'native';
$CFG->dbhost = hefesto_env('DB_HOST');
$CFG->dbname = getenv('DB_NAME') ?: 'postgres';
$CFG->dbuser = hefesto_env('DB_USER');
$CFG->dbpass = hefesto_env('DB_PASSWORD');
$CFG->prefix = 'mdl_';
$ssl = getenv('DB_SSLMODE') ?: 'require';
$insecure_modes = ['disable', 'allow', 'prefer'];
if (!in_array($ssl, ['require', 'verify-full'], true)) {
    if (!in_array($ssl, $insecure_modes, true) || getenv('HEFESTO_ALLOW_INSECURE_DB') !== '1') {
        throw new RuntimeException('DB_SSLMODE debe ser require o verify-full; disable/allow/prefer requieren HEFESTO_ALLOW_INSECURE_DB=1');
    }
}
$CFG->dboptions = ['dbpersist' => false, 'dbsocket' => false, 'dbport' => 5432,
    'dbschema' => 'moodle', 'ssl' => $ssl];
$CFG->wwwroot = rtrim(hefesto_env('MOODLE_URL'), '/');
if (!str_starts_with($CFG->wwwroot, 'https://')) {
    throw new RuntimeException('MOODLE_URL debe usar HTTPS');
}
$CFG->dataroot = '/var/moodledata';
$CFG->admin = 'admin';
$CFG->directorypermissions = 02770;
$CFG->sslproxy = getenv('MOODLE_BEHIND_PROXY') === '1';
$CFG->disableupdateautodeploy = true;
require_once(__DIR__ . '/lib/setup.php');
