# Operacion y aceptacion

Antes de abrir matriculas:
- Entrar como administrador y confirmar Administracion del sitio > Servidor > Entorno.
- Revisar idioma espanol y zona America/Santiago. Configurar nombre, logo, contacto y politicas.
- Configurar SMTP autenticado desde administracion, probar recuperacion de clave con cuenta de prueba. El paquete no trae proveedor de correo.
- Crear categoria, curso, docente y alumno. Matricular alumno manualmente; probar leccion, archivo, cuestionario y calificacion. Verificar que un alumno no accede a cursos privados ajenos ni administracion.
- Confirmar tareas programadas y finalizacion de cron en logs; marcador .hefesto-installed habilita bucle cada 60 segundos despues de cada ejecucion.
- Subir archivo y confirmar persistencia tras reiniciar web/cron. Completar respaldo y restauracion en entorno aislado.
- Revisar cuota de Supabase, disco del VPS, logs y notificaciones. No activar inscripcion publica hasta configurar correo y politica de acceso.

## Respaldar y recuperar

Backup consistente de DOS piezas: PostgreSQL + moodledata. Durante snapshot cerrar escrituras:

```bash
docker compose exec --user www-data web php admin/cli/maintenance.php --enable
docker compose stop cron
# Esperar que terminen solicitudes activas y detener web para no permitir escrituras por APIs.
docker compose stop web
```

Desde una maquina autorizada con PostgreSQL client 17+ usa pg_dump con conexion directa SSL y password en ~/.pgpass protegido (0600), no en URL ni historial:
`pg_dump --host=HOST_DIRECTO --port=5432 --username=moodle_app --dbname=postgres --schema=moodle --format=custom --file=academia.dump` (exportar PGSSLMODE=require o verify-full y PGSSLROOTCERT apropiado).

Respaldar volumen incluso con contenedores detenidos:
`docker compose run --rm --no-deps --user root --entrypoint tar web -czf - -C /var/moodledata . > moodledata.tar.gz`

Guardar juntos dump, tar, commit del paquete, version Moodle e imagen usada. Cifrar respaldos fuera del VPS, con retencion acordada y monitoreo de fallos. No versionar .env; conservar secretos en gestor autorizado.

Tras backup:
```bash
docker compose start web
docker compose exec --user www-data web php admin/cli/maintenance.php --disable
docker compose start cron
```

Para restaurar: crear proyecto PostgreSQL compatible aislado, recrear rol/esquema del SQL, restaurar dump como moodle_app mediante pg_restore --no-owner --no-privileges. Restaurar tar en volumen vacio y asegurar propietario www-data. Usar misma version de codigo, configurar nueva URL y DB, mantener correo/pagos deshabilitados en recuperacion. Abrir web, purgar caches con admin/cli/purge_caches.php, salir de mantenimiento, verificar cursos/archivos/permisos y luego cron. No restaurar encima de produccion sin plan probado.

## Actualizaciones

Version Moodle fijada a 5.3 con checksum verificado. Revisar avisos de seguridad antes de publicar; actualizar URL y SHA oficial en Dockerfile para cada release elegido. Probar en staging con copia protegida, backup completo y mantenimiento. Reconstruir imagen, ejecutar como www-data `php admin/cli/upgrade.php --non-interactive`, purgar caches y verificar. Revertir una migracion exige restaurar DB y archivos junto con codigo; cambiar solo imagen no es rollback suficiente. PHP base no esta fijado por digest: registrar digest real del build para reproducibilidad operativa.
