# Integraciones futuras y traspaso

El prototipo anterior no se convierte automaticamente en Moodle. Este paquete cambia el motor del producto. No se migraron usuarios ni cursos porque no se proporciono un export real. Para datos existentes: inventario, mapeo CSV de usuarios/cursos, pruebas de matricula y backups de curso .mbz cuando procedan. Passwords de otra plataforma no se importan por defecto; flujo de restablecimiento.

La academia se transfiere con imagen/configuracion, dump PostgreSQL, moodledata, dominio y credenciales rotadas. No requiere conservar Supabase: puede migrar a otro PostgreSQL compatible manteniendo esquema y rol. La infraestructura Supabase no convierte Moodle en una app Supabase.

Comercio opcional: WordPress + WooCommerce para vitrina/checkout; Odoo para CRM, ventas y operacion. No necesitas ambos si uno cubre el proceso. Pago confirmado por webhook firmado del proveedor -> registrar evento idempotente -> crear/identificar alumno -> matricular por servicio web Moodle con cuenta y permisos minimos -> registrar resultado y reintentos. Reembolsos/revocaciones requieren regla explicita. No matricular confiando en redireccion del navegador.

n8n puede orquestar eventos con secretos server-side y logs sin contrasenas. Keycloak puede centralizar SSO mediante integracion compatible a seleccionar; no esta activo. Mantener Moodle como autoridad de cursos/notas, ERP como autoridad comercial y proveedor como autoridad del estado del pago.

No se incluye conector operativo, pasarela ni licencia de plugins. Una exportacion CSV hacia Odoo es intercambio de datos, no conversion del codigo a modulo Odoo.
