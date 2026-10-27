# Datos personales — Academia (Moodle)

Contrato del kit `hefesto-academia-moodle-supabase` bajo la **Ley 21.719** (Proteccion de Datos
Personales, Chile). Este documento es normativo para el kit: el despliegue no
se considera completo sin el.

## 1. Inventario de datos

Moodle administra **datos personales de estudiantes y docentes**: nombre, correo, identificador de usuario, datos de matricula, actividad de aprendizaje (entregas, foro, calificaciones), direccion IP de sesion y actividad en el registro. El kit NO administra pagos, identidad legal, nominas ni datos de salud.

## 2. Control de acceso y roles

El kit se conecta a PostgreSQL con un unico rol `moodle_app`, de aplicacion. La separacion entre rol de escritura y rol de lectura es **trabajo pendiente** del cliente: el kit no la implementa y no debe declararse hecha.

## 3. Minimizacion

El respaldo incluye el volcado de la base y el volumen `moodledata`. No incluye `config.php` (contiene el hash de la clave de administracion de Moodle) ni el `.env`. Los datos de matricula de terceros que el docente cargue como archivo se trimming en el propio Moodle.

## 4. Retencion

Retencion propuesta: **5 anos** para el historial academico que el cliente deba conservar por obligacion, **12 meses** para los registros de acceso y **7 dias** para el respaldo verificado. El plazo de los datos academicos lo fija el cliente; el kit deja la propuesta escrita y verificable.

## 5. Supresion, rectificacion y acceso del titular

La supresion de un titular es una operacion del cliente dentro de Moodle (anular la cuenta, anonimizar su actividad) y, cuando corresponda, sobre el volumen `moodledata`. El kit no borra datos por su cuenta: deja el procedimiento y garantiza que el respaldo se verifique antes de restaurar.

## 6. Acceso al respaldo, auditoria y transito

El respaldo sale cifrado cuando hay receptor age. El `moodledata.tar.gz` contiene material de estudiantes: se trata como material cifrado y de acceso restringido. Cada restauracion deja auditoria en `logs/restore-audit.log`.

### Acceso al respaldo y transito

`DB_SSLMODE` por defecto `require` por compatibilidad; **produccion exige `verify-full`** con la CA en `certs/supabase-ca.crt`. `HEFESTO_ALLOW_INSECURE_DB=0` mantiene bloqueados los sslmode inseguros.

## 7. Que NO decide el kit

Los plazos definitivos, la base legal y la incorporacion de los titulares al
registro de actividades de tratamiento son decisiones **del cliente**, no del
kit. Este documento deja la propuesta escrita y verificable; su validacion es
una tarea pendiente de coordinacion.

## 8. Verificacion

```bash
bats tests/                              # ciclo de respaldo con datos sinteticos
python3 scripts/check-env.py --modo real # contrato del .env, sin imprimir valores
python3 scripts/check_backup.py <respaldo>
```
