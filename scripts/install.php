<?php
// Password arrives through stdin, never as an OS process argument.
$password = rtrim((string)fgets(STDIN), "\r\n");
$email = trim((string)fgets(STDIN));
if (strlen($password) < 14 || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    fwrite(STDERR, "Password minimo 14 caracteres y correo valido requeridos.\n"); exit(1);
}
$_SERVER['argv'] = [__FILE__, '--agree-license', '--lang=es', '--adminuser=admin',
    '--adminpass='.$password, '--adminemail='.$email, '--supportemail='.$email,
    '--fullname=Hefesto Academia', '--shortname=Hefesto Academia'];
require '/var/www/moodle/admin/cli/install_database.php';
