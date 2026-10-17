# Hefesto Academia — Moodle + Supabase

Paquete de despliegue nativo. Moodle 5.3 + PHP 8.3/Apache + PostgreSQL de Supabase + volumen moodledata. Docker Compose compatible con un VPS y proxy HTTPS de Coolify.

**Estado:** paquete preparado; no instalado en tu servidor. No contiene credenciales ni cursos reales. No se ha ejecutado Docker ni conectado a Supabase en el entorno de preparacion. Revisar VALIDACION.md. El ZIP descarga Moodle oficial durante el build (93,5 MB) y verifica SHA-256; no incluye una copia completa del LMS.

## Que entrega

- LMS real: cuentas, roles, cursos, actividades, cuestionarios, calificaciones y seguimiento mediante funciones nativas de Moodle.
- PostgreSQL aislado en esquema moodle y rol dedicado; SSL obligatorio.
- Volumen persistente para archivos, cron separado y personalizacion Boost con colores Hefesto.
- Instalador CLI que recibe la clave sin exponerla como argumento del sistema.
- Preflight de extensiones, version PostgreSQL y permisos; guias de operacion, respaldo y futuras integraciones.

No incluye pagos activos, certificados adicionales, SSO, puente Odoo ni migracion automatica del prototipo anterior. Los plugins de terceros se seleccionan y prueban antes de agregarlos.

## Instalar

1. Revisa docs/SUPABASE.md. Usa proyecto dedicado PostgreSQL **17 o superior** y conexion directa accesible desde el VPS.
2. Ejecuta sql/01-supabase.sql una vez con password propio. No expongas esquema moodle por la Data API.
3. Copia .env.example a .env y completa valores. Protege el archivo con `chmod 600 .env`.
4. Sigue docs/COOLIFY.md para conectar dominio HTTPS al servicio web puerto 80.
5. Ejecuta `docker compose up -d --build` en el directorio del paquete.
6. Ejecuta `bash scripts/install.sh` desde esa misma instalacion Compose. Si Coolify gestiona el proyecto, usa la ruta de Compose y nombre de proyecto que genero Coolify: no crees un segundo proyecto o volumen. Ver alternativa de terminal en docs/COOLIFY.md.
7. Configura SMTP, crea un curso de prueba y completa la lista de aceptacion en docs/OPERACION.md.

No basta subir el ZIP a WordPress, Odoo o Sites: Moodle necesita un servidor PHP, cron, PostgreSQL y almacenamiento persistente. Los datos pertenecen a Moodle; Supabase Auth/Storage no sustituyen sus subsistemas automaticamente.

## Modelo comercial sugerido

Implementacion inicial + mensualidad por hosting, soporte, respaldos y actualizaciones. Definir limites de almacenamiento, alumnos activos y soporte en contrato. Cursos, matriculas y cobro son operacion del cliente. Moodle libre no significa infraestructura ni mantenimiento gratis.

Moodle se distribuye bajo GPLv3 o posterior. Esta configuracion se entrega bajo MIT (LICENSE); respeta licencias de Moodle y de cada plugin. Ninguna licencia Enterprise de Odoo se incluye.
