---
name: wp-client-report
description: Convierte el trabajo hecho sobre un sitio (salud, seguridad, conversión de builder, migración de framework, entrega) en un informe HTML/PDF con la marca del cliente. Read-only sobre el sitio; enviar el informe es Human Gate.
---

# wp-client-report — Informe con la marca del cliente

> Recorre las fases canónicas (`rules/skill-phases.md`). Aquí **no se escribe en el sitio**: se lee, se compone y se entrega. La única fase con gate es la entrega, porque un informe que sale al cliente es comunicación externa.

Flujo Kodavio: `diagnostic_audit`. El informe lo **dibuja el agente** donde se ejecuta; el sitio solo aporta datos y marca. Kodavio no lleva librería de PDF a propósito: el agente ya sabe componer con los datos delante, y meterla engordaría el plugin para nada.

## Discovery — de dónde salen los datos

1. `wp-site-session` hecho: sabes a qué sitio apuntas y en qué entorno estás.
2. `kodavio/context-bootstrap` → scope, sistema de diseño, memoria vinculante. El informe se escribe dentro de ese scope, no fuera.
3. **Los datos del informe salen de lo que ya se ejecutó**, no de una pasada nueva a ojo:
   - salud → `wp-site-health` (`wp-get-config-summary`, `wp-list-plugins`, `wp-get-change-log`)
   - seguridad → `wp-security-triage` / `wp-security-cleanup`
   - conversión entre builders → `wp-builder-convert` (informe de cobertura, `materialization_plan`, `dropped`)
   - migración de framework CSS → `kodavio/design-framework-audit` (clases NATIVE / PASSTHROUGH / UNRESOLVED)
   - entrega de página o sitio → lo construido, con sus URLs de preview
4. `kodavio/report-get-branding` → identidad del cliente. Si `configured` es `false`, firma con `site.name` **y dilo** en el pie: el informe nunca sale sin identidad ni con una inventada. La marca se define en el admin, en *Kodavio → Diseño y memoria → Marca para informes*.

**Regla dura: el informe solo afirma lo que una ability devolvió.** Si un dato no está, va como «no verificado», no como suposición. Un informe de cliente es un documento que se guarda y se cita meses después; una cifra inventada ahí sobrevive al proyecto.

## Validate — qué informe es

| Tipo | Qué responde | Sección que no puede faltar |
|---|---|---|
| Salud | ¿cómo está el sitio? | riesgos por severidad + qué hacer y cuándo |
| Seguridad | ¿qué pasó y qué queda? | cronología, alcance, qué se limpió, qué endurecer |
| Conversión de builder | ¿migró todo? | **fidelidad**: qué viajó, qué no, y por qué |
| Migración de framework | ¿se puede soltar el plugin? | clases nativas / pasadas en crudo / sin resolver |
| Entrega | ¿qué he recibido? | qué se construyó, dónde verlo, qué falta para publicar |

Un informe de conversión o migración **sin la lista de lo que no viajó no se entrega**. Es la parte que el cliente necesita y la única que no puede comprobar solo.

## Preview — componer el HTML

Un **único archivo HTML autocontenido**. Sin peticiones a nada externo: se abre desde el correo, desde un móvil sin cobertura o dentro de un visor de PDF, y una hoja de estilos remota que no carga convierte el informe en texto suelto.

- CSS inline, imágenes en `data:` salvo el logo (que es una URL del cliente y sí puede ser remota).
- Aplica la marca: `primary_color` en títulos y filetes, `accent_color` en acentos y estados, `text_color` en el cuerpo, `font_family` con familias de sistema detrás como respaldo.
- `@media print`: sin fondos oscuros a sangre, saltos de página entre secciones, URLs visibles en los enlaces.
- Portada: logo o nombre del cliente, título del informe, sitio, fecha, quién lo firma. Pie: `legal_footer` y `contact` si están.
- Castellano perfecto y **no técnico** (`client-comms.md`). Nada de nombres de abilities, rutas de archivo, IDs internos ni versiones de plugin salvo que el cliente los necesite para decidir.
- **Nunca**: credenciales, tokens, rutas del servidor, capturas del admin con datos de terceros.

## Confirm — antes de que salga

Enséñale a AJ el HTML antes de convertir y antes de enviar. **Human Gate**: mandar el informe al cliente es comunicación externa, igual que un correo.

## Execute — el PDF

El PDF se genera **donde corre el agente**, con lo que haya, por este orden:

1. Chromium/Chrome headless: `--headless --print-to-pdf=informe.pdf --no-pdf-header-footer informe.html`
2. `weasyprint informe.html informe.pdf`
3. `wkhtmltopdf --enable-local-file-access informe.html informe.pdf`

Si no hay ninguno, **entrega el HTML y dilo**. Un HTML bien impreso es un buen entregable; un PDF que no se ha generado no se anuncia como generado. Comprueba siempre que el archivo existe y pesa algo antes de decir que está hecho.

## Report — cerrar

- Deja el informe junto al material del sitio, con fecha en el nombre: `informe-{tipo}-{sitio}-{AAAA-MM-DD}`.
- `kodavio/memory-write` con `source=agent`, `type=decision`: qué se informó, con qué datos y qué quedó pendiente. El siguiente informe empieza donde terminó este.
- Si el informe destapa trabajo (riesgos altos, clases sin resolver, limpieza pendiente), propón la tarea. Un informe que no acaba en trabajo concreto es un documento decorativo.
