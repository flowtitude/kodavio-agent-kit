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

### 0. `registry/marca-informes.txt` — formato y cómo leerlo

Texto plano en castellano, no JSON: una línea por ajuste, `Clave: valor`, comentarios con `#`.
`registry/marca-informes.example.txt` trae **todos** los campos comentados con su valor de
fábrica — es la referencia de qué claves existen y qué variables acepta cada una. Las claves se
reconocen con o sin acentos y sin distinguir mayúsculas/minúsculas (parser en
`scripts/validate-marca-informes.py`, `normalize_key()`); una clave que no reconoce genera un
aviso al validar, no un error. Una clave presente pero con valor vacío (`Logo:` sin nada detrás)
cuenta como "no fijada": usa el default de fábrica, igual que si la línea no existiera.

Al montar un informe, resuelve `registry/marca-informes.txt` **a mano** contra la tabla de abajo
(no hay parser en runtime — es la skill, leyendo el fichero, quien decide qué texto va en cada
sitio). Si el fichero no existe, para y pide `cp registry/marca-informes.example.txt
registry/marca-informes.txt` antes de componer nada.

### 1. Marca — colores, tipografía, logo, emisor

Los tokens viven en el bloque `:root { ... }` al principio de cada fichero (comentario "PUNTOS
DE MARCA"). Sustituir literalmente:

| Custom property / marcador | Clave de `marca-informes.txt` |
|---|---|
| `--color-primary` | `Color principal` |
| `--color-accent` | `Color de acento` |
| `--color-text` | `Color del texto` |
| `--color-cover` | `Color de portada` (si no está fijada, deja la línea `var(--color-primary)` tal cual — ya seguirá a `--color-primary` sin tocar nada) |
| `--font-family` | `Tipografía` |
| `--color-primary-light`, `--color-accent-light` | derivados: mismo tono aclarado ~85-88% hacia blanco (mismo criterio que usaba el panel de demo) |

**No tocar** `--color-ok`, `--color-warning`, `--color-danger`, `--color-neutral` ni sus
variantes `-bg`: son tokens de sistema del semáforo, no de marca (§4 de la especificación —
un cliente con rojo corporativo no puede volver ilegible "todo va mal").

Elementos de marca en el HTML (aparecen 2-3 veces por fichero, `replace_all`):

| Clase / id | Sustituir por |
|---|---|
| `.js-issuer-name` (texto) | `Emisor` |
| `#coverLogo` (contenido interior) | si `Logo` está definida: `<img src="{logo}" alt="">`; si no, la inicial mayúscula de `Emisor` (texto plano, como ya trae la plantilla) |

Las dos fechas/dominios que antes llevaban clase propia (`.js-report-date`, `.js-report-site`)
se retiraron (2026-08-21): esos valores ahora solo hacen falta como variables `{fecha}`/`{sitio}`
para resolver las cuatro plantillas de cabecera/pie de más abajo — la skill sigue necesitando
calcular "fecha del informe" y "dominio auditado" internamente, solo que ya no hay un `<span>`
suelto por cada uno en el HTML.

### 2. Cabecera y pie — cuatro plantillas de texto, misma lógica de resolución

`.js-header-left` / `.js-header-right` (una instancia, dentro del `<thead>`) y `.js-footer-left`
/ `.js-footer-right` (dentro del `<tfoot>`) llevan el resultado de resolver su plantilla de texto
libre contra las variables vigentes — sustituye el **contenido completo** del `<span>`, no solo
una parte:

```
{emisor}       → Emisor
{correo}       → Correo
{telefono}     → Teléfono
{web}          → Web
{legal}        → Texto legal
{fecha}        → fecha del informe ("20 ago 2026"); en informe de tienda, el periodo
{sitio}        → dominio del sitio auditado
{tipo_informe} → "Informe de auditoría web" / "Informe de {Área}" (p. ej. "Informe de SEO") /
                 "Informe de tienda", según qué plantilla se esté componiendo
```

Una variable desconocida o una llave sin cerrar se dejan **tal cual, en texto** — no se ocultan
ni rompen el resto de la cabecera o el pie.

Defaults si `marca-informes.txt` no fija el campo (reproducen el comportamiento de las
plantillas antes de que estos cuatro campos fueran configurables):

- `Cabecera · izquierda`: `{emisor} — {tipo_informe}`
- `Cabecera · derecha`: `{sitio} · {fecha}`
- `Pie · izquierda`: `{emisor} · {correo} · {telefono} · {web}`
- `Pie · derecha`: `{legal}`

`Mostrar "Generado con Kodavio"` (sí/no, `marca-informes.txt`) gobierna el `<span
class="js-powered-by"> · Generado con la tecnología Kodavio.</span>` que cierra
`.js-footer-right`: por defecto está oculto (`.js-powered-by { display: none; }` en el CSS de
impresión). Si es `sí`, borra esa línea CSS (o pon `style="display:inline"` en el span) para que
se imprima. Si es `no` (el default), no toques nada — no forma parte del texto editable de
`footer_right`, para que activar/desactivar no dependa de que el operador se acuerde de
incluirlo en su plantilla.

### 3. Portada — antetítulo, título y fecha configurables

| Clase | Clave de `marca-informes.txt` | Default (si no está fijada) |
|---|---|---|
| `.js-cover-kicker` (`.cover-eyebrow`) | `Portada · antetítulo` | `{tipo_informe}` — literal, se resuelve igual que cabecera/pie |
| `.js-cover-title` (`.cover-title`) | `Portada · título` | el texto que ya trae cada plantilla (varía por tipo: auditoría completa lleva "Estado del sitio y recomendaciones"; área y tienda llevan un título propio de lo que audita ese informe concreto — solo sobrescribe si el operador fijó un valor) |
| `.js-cover-date-line` (el `<span>` completo, no solo el texto) | `Portada · mostrar fecha` | `sí` — si es `no`, **borra el `<span class="js-cover-date-line">` entero** (no solo su texto), la fila de metadatos se reajusta sola con `justify-content: space-between` |

`.cover-title` en área y tienda sigue siendo, ante todo, contenido de la sesión (qué se auditó,
de qué periodo) — `Portada · título` en `marca-informes.txt` es una anulación explícita del
operador para forzar el mismo título en todos los tipos, no el mecanismo normal para el título
de cada informe.

### 4. Contenido del informe — hallazgos, semáforos, cifras

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

### El pie clavado al fondo físico (decisión 2026-08-21)

**`position: fixed` se probó y se descartó** — no por gusto, por un bug determinista de Chrome.
Repro mínima: portada a sangre completa (`@page :first { margin: 0 }`) + `break-after: page` +
`position: fixed; bottom: 0` en el pie de la página siguiente. Resultado, reproducido en 3
variantes de la maqueta y con `--no-pdf-header-footer` + `pdftotext -bbox` página a página:
**el pie fijo no se pinta en la página que sigue justo a la portada — nunca, en ningún run** —
mientras que una cabecera fija (`top: 0`) en la misma página **sí** sobrevive (asimetría
confirmada, no es que "el mecanismo falle en general"). Se probaron variantes para evitar el
disparador (bleed de portada por márgenes negativos en vez de `@page :first`, página con nombre
CSS, redefinir el pie fijo después del salto): ninguna evitó el bug, y el bleed por márgenes
negativos ni siquiera llega a sangrar (Chrome recorta el margen negativo contra el área de
página — no es un problema de *collapsing*, falla igual en el eje horizontal, que nunca
colapsa). Con la portada siempre inmediatamente antes del contenido en las tres plantillas, la
página rota es SIEMPRE una página real del informe — no es un caso raro descartable.

Con la tabla ya puesta (necesaria de todas formas para que el pie **exista** en el 100% de las
páginas), el bug real que había que arreglar no era "cualquier página corta se queda con el pie
a media altura": Chrome ya rellena a página física completa cualquier página intermedia que
tenga más contenido detrás — comprobado forzando una sección "Salud" de una sola línea en medio
del documento: el pie seguía clavado al fondo exacto, con un hueco en blanco de sobra antes.
El único caso real es la **última página del documento**: ahí la tabla termina de verdad, no hay
nada después que obligue a Chrome a rellenar, y si el contenido de esa página no llena el alto
disponible, el pie queda pegado justo debajo del contenido. Como el Anexo técnico es siempre la
última sección (§9.6 de la especificación), el arreglo es acotado: `.print-body .page:last-child
{ min-height: 226mm }` en el bloque `@media print` de las tres plantillas — obliga a esa última
sección a ocupar el alto disponible aunque su contenido sea corto, empujando el pie al fondo real.

El valor 226mm está calibrado con margen de seguridad, no al límite exacto: el hueco entre el
borde de la cabecera y el borde del pie en una página completa mide ~245mm; restando el
padding-top de sección (4mm) y el padding-bottom de página (6mm) da ~235mm de altura de
contenido "perfecta" — pero 235mm ya desborda una página extra en blanco (probado con
`pdfinfo` contando páginas, subiendo el valor de mm en mm: 233mm es seguro, 234mm desborda para
el pie de marca a dos líneas de la maqueta). 226mm deja ~7-8mm de margen extra antes del pie en
vez de 0mm — imperceptible, y evita el riesgo de una página en blanco de sobra si el texto de
marca (`Texto legal` / `Pie · izquierda` largos) ocupa más líneas que en la maqueta. **Si el pie
de marca crece a 3+ líneas por lado, recalibra**: sube el `min-height` de 5 en 5mm y confirma con
`pdfinfo … | grep Pages` que el número de páginas no cambia respecto a sin el `min-height`.

**Verificación aplicada** (no solo textual — posicional, página a página): para cada una de las
tres plantillas, con contenido de ejemplo real (sin recortar), (1) `chrome --headless
--disable-gpu --no-pdf-header-footer --virtual-time-budget=4000 --print-to-pdf`; (2) `pdfinfo …
| grep Pages` antes y después de añadir el `min-height`, para confirmar que no aparece ninguna
página extra en blanco (fue así como se detectó que 235mm desbordaba y se bajó a 226mm); (3)
`pdftoppm -png -r 100/150` de la portada, una página interior completa y la última página, y
lectura de los PNG — no solo `pdftotext`, que no informa de posición — para confirmar visualmente
que el pie de la última página queda a la misma altura que el de una página completa; (4)
`pdftotext -bbox` + Python para extraer la coordenada `yMin` del texto del pie en cada página y
comparar la distancia al borde inferior entre una página completa y la última — la diferencia
observada es de ~7mm (el margen de seguridad del punto anterior), nunca páginas completas de
hueco como antes del arreglo.

Otros mecanismos de impresión que hay que respetar tal cual están, sin CSS Paged Media
(`position:running()`, `@top-center`, `counter(page)`) porque ningún navegador los implementa
para HTML:

- `@page { size: A4; margin: 20mm 16mm 18mm; }` + `@page :first { margin: 0; }` (portada a
  sangre completa). **No sustituir por bleed vía márgenes negativos** — probado, Chrome no lo
  aplica en impresión (ver arriba).
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
