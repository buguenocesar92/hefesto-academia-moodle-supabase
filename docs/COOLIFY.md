# Despliegue en Coolify

1. Sube el contenido a un repositorio privado propio sin .env. Crea recurso Docker Compose desde ese repositorio, archivo compose.yaml. Build requiere acceso a imagen PHP y descarga oficial Moodle.
2. Configura MOODLE_URL, DB_HOST, DB_NAME, DB_USER, DB_PASSWORD y DB_SSLMODE como variables secretas/runtime del recurso. No variables de build.
3. Asigna https://academia.tu-dominio.cl al servicio web, puerto interno 80. DNS hacia servidor. Coolify termina HTTPS y reenvia HTTP interno; MOODLE_BEHIND_PROXY=1 ya esta configurado.
4. Cron no lleva dominio ni puerto publicado. Ambos servicios comparten el volumen moodledata. Conservar nombre del proyecto y volumen entre despliegues.
5. Montaje certs: el repositorio incluye directorio vacio documentado. Para verify-full suministra el archivo CA en el host/montaje persistente de Coolify y apunta ambos servicios a /etc/ssl/certs/custom/supabase-ca.crt.
6. Despliega; healthcheck solo valida Apache, no que Moodle este instalado. La web responde 503 hasta que exista .hefesto-installed; healthz sigue accesible. La instalacion por navegador esta bloqueada: usar CLI.

## Primera instalacion desde terminal Coolify

Si no usas scripts/install.sh en el host de Compose, abre terminal del contenedor web como root. Ejecuta `su -s /bin/bash www-data` para operar como usuario del servidor y luego:

```bash
php /opt/hefesto/preflight.php
read -r -p 'Correo admin: ' email
read -r -s -p 'Clave admin (14+): ' password
printf '\n'
# Continuar implica aceptar GPL de Moodle.
printf '%s\n%s\n' "$password" "$email" | php -d disable_functions=cli_set_process_title /opt/hefesto/install.php
unset password
# Solo ejecutar siguientes comandos si instalador termino sin error:
php /opt/hefesto/brand.php
touch /var/moodledata/.hefesto-installed
```

La instalacion puede tardar. Si falla, no crear el marcador ni reintentar sobre tablas parciales: conservar logs, determinar causa y usar un esquema nuevo/vacio unicamente tras confirmar que no hay datos productivos.

No ejecutar chmod 777 ni usar postgres como usuario runtime. No publicar el puerto 80 directamente a Internet: acceso exterior a traves del proxy HTTPS.

Recomendacion inicial de capacidad para piloto: 2 vCPU, 4 GB RAM y volumen dimensionado a contenidos; es una estimacion a validar con carga, no garantia. Para mas nodos se requiere almacenamiento compartido y revisar sesiones/caches/locks; este paquete es de un solo VPS.
