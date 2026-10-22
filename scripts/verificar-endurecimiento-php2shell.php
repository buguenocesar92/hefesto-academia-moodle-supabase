<?php

declare(strict_types=1);

/**
 * CANDADO: CVE-2026-109618 / CVE-2026-109619 (PHP2Shell, @@FECHA@@).
 *
 * Este repo no tiene framework de pruebas: es una imagen de Moodle con Apache y
 * mod_php, sin `composer.json` ni suite de PHPUnit. El candado es este script,
 * que se puede correr sin instalar nada:
 *
 *     php scripts/verificar-endurecimiento-php2shell.php
 *
 * Y tambien se corre DENTRO de la imagen, como puerta del build (ver el
 * Dockerfile), para que una imagen sin el endurecimiento no se pueda construir:
 *
 *     php scripts/verificar-endurecimiento-php2shell.php --imagen
 *
 * QUE COMPRUEBA
 * -------------
 *   1. Que la base de la imagen use una version de PHP PARCHEADA (las
 *      parcheadas son 8.2.35 / 8.3.36 / 8.4.27 / 8.5.12).
 *   2. Que el ini de endurecimiento apague `session.upload_progress.enabled`,
 *      que es la via CONFIRMADA de CVE-2026-109619.
 *   3. Que la etapa final del Dockerfile copie el ini a `conf.d` y el archivo de
 *      Apache a `conf-available/`, y que lo habilite con `a2enconf`.
 *   4. Que Apache recicle los hijos cada 100 peticiones.
 *   5. Que la etapa final actualice el sistema base.
 *   6. Que NADA en el repo vuelva a encender `session.upload_progress.enabled`.
 *
 * SALE CON CODIGO 0 SI TODO ESTA BIEN, Y CON CODIGO 1 SI ALGO FALLA.
 */

const VERSION_MINIMA = '8.3.36';
const SERIE = '8.3';

const DOCKERFILE = 'Dockerfile';
const INI = 'docker/99-php2shell-hardening.ini';
const APACHE = 'docker/zz-php2shell-apache.conf';

$fallos = [];

/**
 * @return list<string>
 */
function fallos(): array
{
    global $fallos;

    return $fallos;
}

function anota(string $mensaje): void
{
    global $fallos;

    $fallos[] = $mensaje;
}

function raiz(): string
{
    return dirname(__DIR__);
}

function leer(string $ruta): string
{
    return (string) file_get_contents($ruta);
}

/**
 * El texto del Dockerfile con las continuaciones de linea unidas.
 */
function dockerfileUnido(): string
{
    return (string) preg_replace('/\x5c[ \t]*\n[ \t]*/', ' ', leer(raiz().'/'.DOCKERFILE));
}

/**
 * Las lineas de la ETAPA FINAL del Dockerfile.
 *
 * @return list<string>
 */
function lineasDeLaEtapaFinal(): array
{
    $lineas = array_values(array_filter(
        array_map('trim', explode("\n", dockerfileUnido())),
        fn (string $linea): bool => $linea !== '' && ! str_starts_with($linea, '#'),
    ));

    $ultimoFrom = 0;
    foreach ($lineas as $indice => $linea) {
        if (preg_match('/^FROM\s/i', $linea) === 1) {
            $ultimoFrom = $indice;
        }
    }

    return array_slice($lineas, $ultimoFrom);
}

function comprobarLaVersionDeLaBase(): void
{
    $contenido = leer(raiz().'/'.DOCKERFILE);

    if (preg_match('/^FROM\s+(?:docker\.io\/library\/)?php:(\S+)/mi', $contenido, $coincidencia) !== 1) {
        anota('El Dockerfile no declara una base «FROM php:...».');

        return;
    }

    $tag = $coincidencia[1];

    if (preg_match('/^(\d+\.\d+\.\d+)/', $tag, $version) === 1) {
        if (version_compare($version[1], VERSION_MINIMA, '<')) {
            anota('La base «'.$tag.'» esta por debajo de la version parcheada ('.VERSION_MINIMA.') de la serie '.SERIE.'.');
        }

        return;
    }

    preg_match('/^(\d+\.\d+)/', $tag, $serie);
    if (($serie[1] ?? '') !== SERIE) {
        anota('La base «'.$tag.'» no es de la serie '.SERIE.', que es la que tiene la version parcheada ('.VERSION_MINIMA.').');
    }
}

function comprobarLaVersionVerificada(): void
{
    $ini = leer(raiz().'/'.INI);

    if (preg_match('/PHP verificado:\s*(\d+\.\d+\.\d+)/', $ini, $coincidencia) !== 1) {
        anota(INI.' no deja constancia de la version de PHP con la que se construyo la imagen.');

        return;
    }

    if (version_compare($coincidencia[1], VERSION_MINIMA, '<')) {
        anota('La version de PHP verificada ('.$coincidencia[1].') esta por debajo de la version parcheada ('.VERSION_MINIMA.') de la serie '.SERIE.'.');
    }
}

function comprobarElIni(): void
{
    $ruta = raiz().'/'.INI;

    if (! is_file($ruta)) {
        anota('Falta '.INI.': la imagen queda con los valores de fabrica de PHP.');

        return;
    }

    $valores = parse_ini_file($ruta, false, INI_SCANNER_TYPED);

    if (! is_array($valores)) {
        anota(INI.' no se puede leer como ini.');

        return;
    }

    if (! array_key_exists('session.upload_progress.enabled', $valores)) {
        anota(INI.' no fija «session.upload_progress.enabled»: es la via CONFIRMADA del UAF de CVE-2026-109619.');

        return;
    }

    if ($valores['session.upload_progress.enabled']) {
        anota(INI.' deja «session.upload_progress.enabled» encendido: PHP lo trae en On por omision.');
    }
}

function comprobarLasCopias(): void
{
    $etapa = implode("\n", lineasDeLaEtapaFinal());

    if (preg_match('#^COPY\s+'.preg_quote(INI, '#').'\s+/usr/local/etc/php/conf\.d/[\w.-]+\.ini$#m', $etapa) !== 1) {
        anota('La etapa final del Dockerfile no copia '.INI.' a /usr/local/etc/php/conf.d/: el endurecimiento no llega al contenedor.');
    }

    if (preg_match('#^COPY\s+'.preg_quote(APACHE, '#').'\s+/etc/apache2/conf-available/[\w.-]+\.conf$#m', $etapa) !== 1) {
        anota('La etapa final del Dockerfile no copia '.APACHE.' a /etc/apache2/conf-available/: el reciclaje de los hijos no llega al contenedor.');
    }

    if (str_contains($etapa, 'a2enconf zz-php2shell-hardening') === false) {
        anota('El Dockerfile no habilita el archivo de Apache con «a2enconf zz-php2shell-hardening».');
    }
}

function comprobarElReciclajeDeApache(): void
{
    $ruta = raiz().'/'.APACHE;

    if (! is_file($ruta)) {
        anota('Falta '.APACHE.'.');

        return;
    }

    if (preg_match('/^\s*MaxRequestsPerChild\s+100\s*$/m', leer($ruta)) !== 1) {
        anota(APACHE.' no fija «MaxRequestsPerChild 100»: sin el, Apache usa 1000 peticiones por hijo.');
    }
}

function comprobarLaActualizacionDelSistema(): void
{
    $etapa = implode("\n", lineasDeLaEtapaFinal());

    if (preg_match('/apt-get\s+upgrade|apk\s+update\s*&&\s*apk\s+upgrade/', $etapa) !== 1) {
        anota('La etapa final del Dockerfile no actualiza el sistema base («apt-get upgrade»): las librerias del sistema quedan en la version vulnerable.');
    }
}

function comprobarQueNadaEnciendeElUploadProgress(): void
{
    $archivos = [raiz().'/'.DOCKERFILE];

    $iterador = new RecursiveIteratorIterator(
        new RecursiveDirectoryIterator(raiz(), FilesystemIterator::SKIP_DOTS),
    );

    foreach ($iterador as $archivo) {
        $ruta = $archivo->getPathname();

        if (str_contains($ruta, '/vendor/') || str_contains($ruta, '/node_modules/')) {
            continue;
        }

        if (in_array(strtolower($archivo->getExtension()), ['ini', 'sh'], true)) {
            $archivos[] = $ruta;
        }
    }

    foreach ($archivos as $archivo) {
        if (realpath($archivo) === realpath(raiz().'/'.INI)) {
            continue;
        }

        foreach (explode("\n", leer($archivo)) as $linea) {
            $linea = trim($linea);

            if (str_starts_with($linea, '#') || str_starts_with($linea, ';')) {
                continue;
            }

            if (preg_match('/session\.upload_progress\.enabled\s*=\s*["\']?(1|on|true|yes)\b/i', $linea) === 1) {
                anota(basename($archivo).' vuelve a encender session.upload_progress.enabled: «'.$linea.'»');
            }
        }
    }
}

/**
 * Comprobaciones dentro de la imagen ya construida.
 */
function comprobarLaImagen(): void
{
    $ini = '/usr/local/etc/php/conf.d/99-php2shell-hardening.ini';

    if (! is_file($ini)) {
        anota('La imagen no tiene '.$ini.'.');

        return;
    }

    $valores = parse_ini_file($ini, false, INI_SCANNER_TYPED);
    if (! is_array($valores) || ($valores['session.upload_progress.enabled'] ?? null) !== false) {
        anota('En la imagen, «session.upload_progress.enabled» no esta en Off.');
    }

    $apache = '/etc/apache2/conf-available/zz-php2shell-hardening.conf';

    if (! is_file($apache)) {
        anota('La imagen no tiene '.$apache.'.');

        return;
    }

    if (preg_match('/^\s*MaxRequestsPerChild\s+100\s*$/m', leer($apache)) !== 1) {
        anota('En la imagen, «MaxRequestsPerChild 100» no esta.');
    }

    if (! is_link('/etc/apache2/conf-enabled/zz-php2shell-hardening.conf')
        && ! is_file('/etc/apache2/conf-enabled/zz-php2shell-hardening.conf')) {
        anota('En la imagen, el archivo de Apache no esta habilitado en conf-enabled/.');
    }
}

$modoImagen = in_array('--imagen', $argv, true);

if ($modoImagen) {
    comprobarLaImagen();
} else {
    comprobarLaVersionDeLaBase();
    comprobarLaVersionVerificada();
    comprobarElIni();
    comprobarLasCopias();
    comprobarElReciclajeDeApache();
    comprobarLaActualizacionDelSistema();
    comprobarQueNadaEnciendeElUploadProgress();
}

if (fallos() !== []) {
    fwrite(STDERR, "CANDADO PHP2Shell: FALLA\n");
    foreach (fallos() as $mensaje) {
        fwrite(STDERR, '  - '.$mensaje."\n");
    }

    exit(1);
}

fwrite(STDOUT, 'CANDADO PHP2Shell: OK ('.($modoImagen ? 'imagen' : 'repo').")\n");

exit(0);
