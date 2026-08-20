# Plantillas de `wp-client-report`

Tres ficheros HTML **reales y completos**, no un motor de plantillas: el kit no ejecuta nada
(doctrina "el kit es cabeza y criterio, no manos"). La skill clona el fichero del tipo de
informe que toque y rellena a mano las zonas marcadas, dejando intactas la estructura, las
reglas de impresión y las custom properties de marca.

| Fichero | Tipo de informe | Áreas |
|---|---|---|
| `informe-auditoria-completa.html` | Auditoría completa | Salud + Seguridad + Rendimiento + SEO + Accesibilidad + Tienda (si vende) |
| `informe-area.html` | Informe por área | Una sola área (la plantilla trae SEO como ejemplo) |
| `informe-tienda.html` | Informe de tienda | Solo Tienda: resumen del periodo, catálogo/stock, hallazgos operativos |

Ninguna lleva ya panel de demo ni JavaScript: eran solo para probar la personalización en vivo
mientras se aprobaba el diseño. La sustitución real la hace la skill editando el HTML
directamente, no un script en el navegador.

## Qué sustituye la skill

### 1. Marca — desde `registry/report-branding.json`

Los tokens viven en el bloque `:root { ... }` al principio de cada fichero (comentario "PUNTOS
DE MARCA"). Sustituir literalmente:

| Custom property / marcador | Campo de `report-branding.json` |
|---|---|
| `--color-primary` | `primary_color` |
| `--color-accent` | `accent_color` |
| `--color-text` | `text_color` |
| `--font-family` | `font_family` |
| `--color-primary-light`, `--color-accent-light` | derivados: mismo tono aclarado ~85-88% hacia blanco (mismo criterio que usaba el panel de demo) |

**No tocar** `--color-ok`, `--color-warning`, `--color-danger`, `--color-neutral` ni sus
variantes `-bg`: son tokens de sistema del semáforo, no de marca (§4 de la especificación —
un cliente con rojo corporativo no puede volver ilegible "todo va mal").

Elementos de marca en el HTML (aparecen 2-3 veces por fichero, `replace_all`):

| Clase / id | Sustituir por |
|---|---|
| `.js-issuer-name` (texto) | `issuer_name` |
| `#coverLogo` (contenido interior) | si `logo` está definido: `<img src="{logo}" alt="">`; si no, la inicial mayúscula de `issuer_name` (texto plano, como ya trae la plantilla) |
| `.js-report-date` (texto) | fecha del informe, formato "20 ago 2026" |
| `.js-report-site` (texto) | dominio del sitio auditado |

### 2. Pie de página — `footer_left` / `footer_right`, resueltos a mano

`.js-footer-left` y `.js-footer-right` (una instancia cada uno, dentro del `<tfoot>`) llevan el
resultado de resolver la plantilla de texto libre contra las variables vigentes — la misma
lógica que hacía `resolveTemplate()` en el JS de demo, ahora la aplica la skill al montar el
HTML:

```
{emisor}   → issuer_name
{correo}   → contact.email
{telefono} → contact.phone
{web}      → contact.web
{legal}    → legal_footer
{fecha}    → la misma fecha que .js-report-date
{sitio}    → la misma que .js-report-site
```

Una variable desconocida o una llave sin cerrar se dejan **tal cual, en texto** — no se ocultan
ni rompen el resto del pie.

Defaults si `report-branding.json` no fija `footer_left`/`footer_right` (reproducen el
comportamiento previo a que existieran estos dos campos):

- `footer_left`: `{emisor} · {correo} · {telefono} · {web}`
- `footer_right`: `{legal}`

`show_powered_by` (booleano, `report-branding.json`) gobierna el `<span class="js-powered-by">
· Generado con la tecnología Kodavio.</span>` que cierra `.js-footer-right`: por defecto está
oculto (`.js-powered-by { display: none; }` en el CSS de impresión). Si `show_powered_by` es
`true`, borra esa línea CSS (o pon `style="display:inline"` en el span) para que se imprima. Si
es `false` (el default), no toques nada — no forma parte del texto editable de `footer_right`,
para que activar/desactivar no dependa de que el operador se acuerde de incluirlo en su
plantilla.

### 3. Contenido del informe — hallazgos, semáforos, cifras

Todo lo que hay entre `<thead class="print-head">` y `<tfoot class="print-foot">` es **contenido
de ejemplo** (marcado con el banner superior `.example-banner`, oculto en impresión) que la
skill sustituye sección por sección con los datos reales de la sesión:

- **Semáforo** (`.dot-ok` / `.dot-warning` / `.dot-danger` en el resumen; `.pill-ok` /
  `.pill-warning` / `.pill-danger` en cada área): verde/ámbar/rojo según severidad máxima de
  la sección — colores fijos, no de marca (ver arriba).
- **Hallazgo** (`.finding.sev-alto` / `.sev-medio` / `.sev-bajo`): título, frase no técnica de
  "por qué importa" y `.finding-evidence` con la fuente exacta (ability/sesión + campo + valor +
  fecha) — la misma evidencia que luego repite el anexo.
- **Sin cobertura**: si `coverage_check(area)` da `none`, no se inventa un hallazgo — se usa el
  bloque `.no-coverage` (ya en `informe-auditoria-completa.html`) con el texto "sin cobertura
  verificable en este sitio todavía" en vez de la lista de `.finding`.
- **Recomendaciones** (`.reco-list`): una lista única, todas las áreas mezcladas, ordenada por
  severidad — no repetir por área.
- **Anexo técnico** (`table.annex-table`): una fila por dato citado arriba — fuente, campo,
  valor, fecha. Siempre presente, siempre al final (§9.6 de la especificación).
- **Tienda** (`.stats-row`, `table.product-table`): cifras del periodo tal cual las devuelve la
  ability de ventas — nunca inferidas.

**Regla dura heredada de la skill**: el informe solo afirma lo que una ability devolvió. Un dato
sin verificar va como "no verificado", nunca como suposición.

Antes de entregar, borra el `.example-banner` (o dale el texto real si el operador quiere un
aviso propio) — su única función en el fichero versionado es marcar que lo que hay debajo es
contenido de ejemplo.

## Mecanismo de impresión — no tocar sin releer esto

Cabecera y pie repetidos en cada página usan una `<table class="print-shell">` con
`<thead>`/`<tbody>`/`<tfoot>` **reales** (no `display:table` sobre `<div>`): es la única forma
que Chrome respeta para repetir cabecera/pie en todas las páginas de una sección que se reparte
en varias por overflow natural, no solo en saltos forzados. Verificado con
`chrome --headless --no-pdf-header-footer --print-to-pdf` + `pdftotext` página a página antes de
mover las plantillas al kit: cabecera y pie presentes en el 100% de las páginas interiores
(11 páginas / 10 interiores en auditoría completa, 5/4 en área, 6/5 en tienda — mismos números
que la maqueta aprobada). Si en algún cambio futuro se sustituye `<table>` por `<div>` con
`display:table`, el bug vuelve: Chrome solo pinta `thead` en la primera página de la tabla y
`tfoot` en la última.

Otros mecanismos de impresión que hay que respetar tal cual están, sin CSS Paged Media
(`position:running()`, `@top-center`, `counter(page)`) porque ningún navegador los implementa
para HTML:

- `@page { size: A4; margin: 20mm 16mm 18mm; }` + `@page :first { margin: 0; }` (portada a
  sangre completa).
- `break-after: page` en `.cover`, `break-before: page` entre `.page` dentro del `<tbody>`.
- `break-inside: avoid` en cada tarjeta de hallazgo, estadística, fila de recomendación y fila
  del anexo — el área completa sí puede repartirse en varias páginas, la tarjeta individual no.
- `print-color-adjust: exact` (con los alias `-webkit-` y sin prefijo) para que el semáforo no
  pierda el color al imprimir.

## Salida y nombre de fichero

HTML autocontenido (CSS inline, sin peticiones externas salvo el logo del cliente) es la base y
el mínimo entregable. PDF por la cadena de fallback de `SKILL.md` (Chromium/Chrome headless →
`weasyprint` → `wkhtmltopdf`). Nombre único por informe (lección del 20-ago-2026: nunca dos
entregas con el mismo nombre) — ver `SKILL.md` § Report para el patrón exacto.
