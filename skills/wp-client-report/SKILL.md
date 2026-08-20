---
name: wp-client-report
description: Informe de marca blanca (HTML/PDF) sobre un sitio WordPress — auditoría completa, una sola área (salud/seguridad/rendimiento/SEO/accesibilidad) o tienda. Read-only sobre el sitio; entregarlo es Human Gate.
---

# wp-client-report — Informe de marca blanca

> Recorre las fases canónicas (`rules/skill-phases.md`). Aquí **no se escribe en el sitio**: se lee, se compone y se entrega. La única fase con gate es la entrega, porque un informe que sale al cliente es comunicación externa.

Flujo Kodavio: `diagnostic_audit`. El informe lo **dibuja el agente** donde se ejecuta, sobre las plantillas de `skills/wp-client-report/templates/` (contrato de sustitución en `templates/README.md`); el sitio solo aporta datos. Kodavio no lleva librería de PDF a propósito.

**La marca vive en el kit, no en el sitio** (decisión 2026-08-20): se personaliza una vez para todos los sitios que operas, en `registry/report-branding.json` — no hay ability del plugin que la sirva ni falta que la haya (migración desde la versión anterior de esta skill: `CHANGELOG.md`).

## Discovery — de dónde salen los datos

1. `wp-site-session` hecho: sabes a qué sitio apuntas y en qué entorno estás.
2. `kodavio/context-bootstrap` → scope, sistema de diseño, memoria vinculante.
3. **Marca**: lee `registry/report-branding.json`. **Si no existe, para y pide configurarlo** —
   `cp registry/report-branding.example.json registry/report-branding.json` y rellenar
   `issuer_name` como mínimo. No hay fallback silencioso a un nombre inventado: es una
   decisión deliberada (antes la ability del sitio sí tenía ese fallback; el kit no, porque
   aquí "no configurado" significa que nadie ha decidido todavía qué marca lleva el informe).
4. **Cobertura por área**: `kodavio/capability-map` (expone `coverage_check` por área) para
   cada área que entre en el tipo de informe pedido — `covered` / `probable` / `none`. No se
   asume que un área tiene datos: se pregunta primero.
5. **Datos por área**, solo si `coverage_check` dio `covered` o `probable`:
   - **Salud** → `kodavio/page-health-check`, `kodavio/wp-get-config-summary`, `kodavio/wp-list-plugins`, `kodavio/wp-get-change-log`, `kodavio/analytics-site-summary`, `kodavio/builder-editor-open-check`.
   - **SEO** → `kodavio/seo-detect` (qué plugin), `kodavio/seo-analyze`, `kodavio/seo-read`.
   - **Seguridad** → sin ability propia de auditoría normalizada hoy. Sale de una sesión ya
     ejecutada de `wp-security-triage`, citada como fuente (fecha + qué se encontró). No se
     lanza una triage nueva solo para el informe.
   - **Rendimiento** y **Accesibilidad** → sin ability propia hoy ("Por construir" en el mapa
     de cobertura). Si `coverage_check` da `none` — el caso normal — **no se inventa una
     medición**: la sección va con semáforo gris y "sin cobertura verificable en este sitio
     todavía" (ver `templates/README.md`, bloque `.no-coverage`). Solo se citan datos si el
     agente hizo de verdad una medición manual en esta sesión, con fecha y método, nunca como
     relleno para no dejar la sección vacía.
   - **Tienda — WooCommerce** → `kodavio/wc-get-status`, `kodavio/wc-sales-report`,
     `kodavio/wc-orders-summary`, `kodavio/wc-list-products`, `kodavio/wc-read-order`,
     `kodavio/analytics-commerce-summary`.
   - **Tienda — FluentCart** → sin wrapper `kodavio/wc-*`. `mcp-adapter-discover-abilities`
     para ver qué expone el proveedor `fluent-cart`, luego `mcp-adapter-execute-ability` sobre
     esas abilities absorbidas. Los datos llegan en crudo del plugin: normalízalos a las mismas
     categorías que usa la sección Tienda (ventas del periodo, ticket medio, catálogo/stock)
     antes de redactar, no los pegues tal cual.

**Regla dura, heredada sin cambios: el informe solo afirma lo que una ability devolvió.** Un
dato sin verificar va como «no verificado», nunca como suposición. Un informe de cliente se
guarda y se cita meses después; una cifra inventada ahí sobrevive al proyecto.

## Validate — qué tipo de informe, qué áreas

Los tres tipos comparten motor y plantilla (`templates/`); cambia el filtro de áreas y el foco
del resumen ejecutivo.

| Tipo | Áreas | Plantilla | Cuándo |
|---|---|---|---|
| **Auditoría completa** | Salud + Seguridad + Rendimiento + SEO + Accesibilidad + Tienda (si el sitio vende) | `templates/informe-auditoria-completa.html` | "Hazme un informe del sitio", entrega de proyecto, revisión periódica |
| **Informe por área** | Una sola de las cinco áreas de análisis | `templates/informe-area.html` | "Pásame el informe de SEO", seguimiento de un hallazgo concreto |
| **Informe de tienda** | Solo Tienda (WooCommerce o FluentCart, la que `coverage_check('store')` detecte) | `templates/informe-tienda.html` | Reporte de ventas/catálogo para el dueño de la tienda, sin mezclar con salud técnica |

Si piden auditoría completa o informe de tienda y `coverage_check('store')` da `none`: dilo
antes de prometer la sección — no se incluye una sección Tienda vacía ni "próximamente".

Todas las secciones son obligatorias en auditoría completa; en por-área y de tienda se omiten
las que no aplican, nunca se dejan vacías con un título suelto.

## Preview — componer el HTML

Clona la plantilla del tipo elegido y sustitúyela siguiendo el contrato exacto de
`templates/README.md` (custom properties de marca, bindings `.js-*`, pie con variables,
`show_powered_by`, contenido de ejemplo a reemplazar por hallazgos reales). No es un motor de
plantillas: se edita el HTML a mano, sección por sección.

- **Severidad** normalizada a Alto/Medio/Bajo (mismo vocabulario que `wp-site-health`, no se
  inventa una segunda taxonomía): `seo-analyze` → `error`/`warning`/`notice` mapea 1:1; `page-health-check` → Alto si afecta `frontend_ok`/`builder_data_ok`, Medio el resto; hallazgos de
  seguridad citados desde `wp-security-triage` → comprometido = Alto, sospechoso = Medio.
- **Semáforo sin puntuación numérica** (decisión 2026-08-20 §9.1): solo verde/ámbar/rojo. Una
  puntuación 0-100 exigiría una fórmula de ponderación que hoy no existe en ninguna ability —
  inventarla sería justo lo que prohíbe la regla dura de arriba.
- **Resumen ejecutivo**: castellano no técnico (`agentkit/rules/copy-review.md` si trabajas en
  el entorno SA; en general, sin nombres de ability, rutas ni IDs internos), semáforo por área
  en una fila, un párrafo de estado general, y los 3-5 hallazgos que más importan explicados en
  una frase cada uno.
- **Recomendaciones priorizadas**: una lista única mezclando todas las áreas incluidas, ordenada
  por severidad — el cliente no organiza su semana por área técnica.
- **Anexo técnico**: siempre presente, siempre al final (decisión 2026-08-20 §9.6) — ability o
  fuente exacta, campo, valor, timestamp de cada dato citado arriba.
- **Castellano fijo** (decisión 2026-08-20 §9.5): el informe sale siempre en castellano, sin
  mirar el campo `language` del sitio en `registry/sites.json`.
- **Nunca**: credenciales, tokens, rutas del servidor, capturas del admin con datos de terceros.

## Confirm — antes de que salga

Enséñale a AJ el HTML antes de convertir y antes de enviar. **Human Gate siempre**: mandar el
informe al cliente es comunicación externa, igual que un correo. No hay atajo por tipo de
informe ni por urgencia del cliente.

## Execute — el PDF

El PDF se genera **donde corre el agente**, con lo que haya, por este orden:

1. Chromium/Chrome headless: `--headless --no-pdf-header-footer --print-to-pdf=informe.pdf informe.html`
2. `weasyprint informe.html informe.pdf`
3. `wkhtmltopdf --enable-local-file-access informe.html informe.pdf`

Si no hay ninguno, **entrega el HTML y dilo**. El HTML autocontenido ya trae `@media print`
completo (portada a sangre completa, saltos de página por sección, cabecera/pie repetidos vía
`<table>` real — ver `templates/README.md`): abrirlo e imprimirlo desde el navegador funciona
sin generar PDF. Un HTML bien impreso es un buen entregable; un PDF que no se ha generado no se
anuncia como generado. Comprueba siempre que el archivo existe y pesa algo antes de decir que
está hecho.

## Report — cerrar

- **Nombre de fichero único** — lección del 20-ago-2026: nunca dos entregas con el mismo
  nombre. Patrón: `informe-{tipo}-{sitio}-{AAAA-MM-DD}-v{N}.{html|pdf}`, donde `{tipo}` es
  `auditoria-completa` / `area-{area}` / `tienda`, y `{N}` es el primer entero libre para ese
  `tipo+sitio+fecha` (mira lo que ya existe en el destino antes de escribir; empieza en `v1`).
  Guarda junto al material del sitio, en `sites/{slug}/informes/`.
- `kodavio/memory-write` con `source=agent`, `type=decision`: qué se informó, con qué datos y
  qué quedó pendiente. El siguiente informe empieza donde terminó este.
- Si el informe destapa hallazgos Altos sin resolver, propón la tarea concreta. Un informe que
  no acaba en trabajo concreto es un documento decorativo.
