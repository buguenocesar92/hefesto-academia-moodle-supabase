# Plataforma recomendada por producto

Criterio: usar primero una herramienta existente que resuelva la operacion; desarrollar extensiones e integraciones donde haya diferencia real. Revisado el sitio https://hefesto-studio.cl/ el 14-10-2026. El sitio presenta tecnologias e implementaciones propuestas, no prueba de instalaciones ni licencias activas.

| Producto | Primera eleccion propuesta | Complemento / condicion |
|---|---|---|
| Academia | Moodle | Supabase PostgreSQL compatible; volumen moodledata; WooCommerce u Odoo solo si requiere venta/gestion comercial |
| POS / comercio | Odoo POS + Inventario | Evaluar edicion/modulos y operacion local; ERPNext alternativa a diagnosticar |
| Distribuidora | Odoo Ventas + Compras + Inventario | ERPNext como alternativa ERP abierta; evitar dos inventarios maestros |
| Taller | Odoo Reparaciones + Inventario | Extension para recepcion, fotos y flujo particular del taller |
| Mantenciones | Odoo Mantenimiento | Servicio en terreno y contratos requieren evaluar modulos/edicion adicional |
| Cotizaciones | Odoo Ventas | Dolibarr alternativa para pyme con gestion mas simple |
| Reservas | Odoo Citas si encaja edicion/costo | Evaluar agenda, recursos, pagos y prevencion de solapamientos antes de elegir |
| Soporte | Chatwoot para conversaciones | Mesa de tickets/SLA requiere evaluar Odoo Helpdesk u otra herramienta especifica |
| Arriendos | Odoo Alquiler | Validar edicion, garantias, disponibilidad y devoluciones del caso real |
| Sitio/tienda | WordPress + WooCommerce | ERP via API solo cuando haga falta; Flow/Webpay segun contrato/proveedor |
| Documentos/equipo | Nextcloud | Keycloak para identidad si hay multiples servicios y capacidad operativa |
| Proyectos | OpenProject | ERP solo para presupuesto/comercial si se requiere |
| Marketing | Mautic | Consentimiento, proveedor correo y limites de envio configurados |
| Contenido multicanal | Strapi | Frontend dedicado solo si aporta algo sobre WordPress |
| Aplicacion diferenciada | Laravel o stack frontend/backend acorde al caso | Supabase si aporta PostgreSQL/Auth/Storage; no obligatorio en herramientas existentes |

Estas son propuestas de arquitectura, no confirmacion de modulos gratuitos. Verificar edicion, licencia, soporte y costos por proyecto. ERPNext, Dolibarr y Odoo tienen motores/requisitos propios: no imponer Supabase a todos. Evitar montar diez servicios para una pyme que necesita dos.

Fuentes de alcance: https://hefesto-studio.cl/ ; https://www.odoo.com/documentation/19.0/applications.html ; https://moodledev.io/general/releases/5.3 ; https://supabase.com/docs/guides/database/connecting-to-postgres
