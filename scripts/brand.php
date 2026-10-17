<?php
define('CLI_SCRIPT', true);
require '/var/www/moodle/config.php';
set_config('theme', 'boost');
set_config('brandcolor', '#b94720', 'theme_boost');
set_config('scss', file_get_contents('/opt/branding/hefesto.scss'), 'theme_boost');
set_config('timezone', 'America/Santiago');
set_config('forcelogin', 1);
set_config('registerauth', '');
theme_reset_all_caches();
echo "Marca Hefesto aplicada; acceso requiere cuenta; autorregistro desactivado.\n";
