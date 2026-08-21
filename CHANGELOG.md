# Changelog — kodavio-agent-kit

> Qué cambia en cada actualización del kit y, sobre todo, **si tienes que migrar algo local**
> (`registry/sites.json`, `sites/{slug}/`). Si una entrada no dice "migración", `git pull` basta.

## 2026-08-21

### Añadido
- **Pie de informe clavado al fondo físico de cada página** (`skills/wp-client-report/templates/*.html`)
  — antes, en páginas cortas, el pie repetido quedaba a media altura. `position: fixed` se probó
  primero y se descartó: incompatible con la portada a sangre completa (Chrome no pinta el pie
  fijo en la página que sigue justo a la portada — bug determinista, no una condición de carrera).
  Se mantiene la `<table>` de cabecera/pie ya existente y se acota el bug real: solo la última
  página del documento (donde la tabla termina de verdad) podía dejar el pie pegado al contenido.
  Arreglo: `min-height` calibrado en el último `.page` (siempre el Anexo técnico). Verificado
  posicionalmente — `pdftoppm` + `pdftotext -bbox`, no solo presencia textual — en las tres
  plantillas. Detalle, evidencia y cómo recalibrar si el pie de marca crece: `templates/README.md`.
- **Cabecera y portada configurables desde `registry/marca-informes.txt`** — `Cabecera · izquierda`
  / `Cabecera · derecha` (plantillas de texto, mismo mecanismo que el pie, más la variable nueva
  `{tipo_informe}`), `Portada · antetítulo`, `Portada · título`, `Portada · mostrar fecha` y
  `Color de portada` (antes heredaba siempre el color principal; ahora es su propio ajuste con ese
  valor como default). Todos con default = comportamiento exacto de los PDF anteriores a este
  cambio. Contrato completo: `templates/README.md`.

### Cambiado
- **`registry/report-branding.json` (+ `.example.json` + `.schema.json`) → `registry/marca-informes.txt`
  (+ `.example.txt`)** — decisión de AJ: texto plano en castellano (`Clave: valor`, comentarios con
  `#`), no JSON, para que configurar la marca no exija saber qué es JSON. Claves reconocidas con o
  sin acentos y sin distinguir mayúsculas/minúsculas; clave desconocida = aviso, no error. Nuevo
  validador `scripts/validate-marca-informes.py` (sustituye a `scripts/validate-report-branding.py`,
  que se retira junto con el schema JSON).

### Notas — migración
- Si venías del `report-branding.json` anterior: `cp registry/marca-informes.example.txt
  registry/marca-informes.txt` y traslada tus valores al formato `Clave: valor` (tabla de
  equivalencias en `templates/README.md`). El fichero JSON ya no se lee — `scripts/doctor.sh`
  solo valida `marca-informes.txt`.

## 2026-08-20

### Añadido
- **`registry/report-branding.json`** (+ `.example.json` + `.schema.json`, mismo patrón que
  `sites.json`) — marca de quién firma los informes de cliente, **a nivel de kit, no por
  sitio**: `issuer_name`, `logo`, colores, tipografía, contacto, `legal_footer` y las dos
  plantillas de pie de página de texto libre `footer_left`/`footer_right` (variables `{emisor}`
  `{correo}` `{telefono}` `{web}` `{legal}` `{fecha}` `{sitio}`), y `show_powered_by` (por
  defecto `false` — marca blanca total salvo activación explícita). Validado por
  `scripts/validate-report-branding.py`, enganchado a `scripts/doctor.sh`.
- **`skills/wp-client-report/templates/`** — las tres plantillas HTML reales (auditoría
  completa, por área, de tienda) que la skill clona y rellena a mano para componer cada
  informe; sin motor de plantillas ni JavaScript de runtime. Contrato de sustitución completo
  en `templates/README.md`. El mecanismo de cabecera/pie repetidos en impresión (`<table>`
  real con `thead`/`tbody`/`tfoot`, no `display:table` sobre `<div>`) queda verificado
  página a página con `chrome --headless --print-to-pdf` + `pdftotext`.

### Cambiado
- **`skills/wp-client-report/SKILL.md`** reescrita por completo sobre el diseño aprobado del
  20-ago: los tres tipos de informe pasan a ser auditoría completa / por área / de tienda,
  filtrados por `coverage_check` (`kodavio/capability-map`) en vez del catálogo ad hoc anterior
  (salud/seguridad/conversión de builder/migración de framework/entrega). Si un área da `none`,
  el informe no inventa una sección: semáforo gris y "sin cobertura verificable". Nombre de
  fichero con versión (`informe-{tipo}-{sitio}-{AAAA-MM-DD}-v{N}`) para que dos entregas del
  mismo día no se pisen.

### Notas — migración
- **La ability `kodavio/report-get-branding` (marca por sitio, Kodavio 0.3) queda deprecada
  en el plugin.** Esta skill ya no la usa ni tiene fallback a ella. Si venías de la versión
  anterior: `cp registry/report-branding.example.json registry/report-branding.json`, copia
  ahí lo que tuvieras en *Kodavio → Diseño y memoria → Marca para informes* de cada sitio y
  quédate con una sola marca de operador para todos. Sin ese fichero, la skill para y lo pide
  antes de componer cualquier informe — no firma con un nombre inventado.
- Los tipos de informe "conversión de builder", "migración de framework" y "entrega" que traía
  la versión anterior de la skill **no tienen equivalente en el nuevo diseño** (el `coverage_check`
  del que dependen los seis tipos actuales solo cubre salud/seguridad/rendimiento/SEO/accesibilidad/tienda).
  Si siguen haciendo falta como informe de cliente, es una ampliación aparte, no una migración.

## 2026-07-29

### Añadido
- **Skill `wp-client-report`** — convierte el trabajo ya hecho sobre un sitio (salud, seguridad, conversión de builder, migración de framework, entrega) en un informe HTML/PDF con la marca del cliente. Read-only sobre el sitio; entregar el informe es Human Gate por ser comunicación externa.

### Cambiado
- **`LICENSE` (MIT)** — venia de `kodavio-skills`, que es el repo que este sustituye. Un repo publico sin licencia es «todos los derechos reservados», que contradice a un kit que se anuncia como clonable.

### Notas
- El reparto es deliberado: el plugin guarda la **marca** y sirve los **datos** (`kodavio/report-get-branding`, Kodavio 0.3); el informe lo **dibuja el agente** donde se ejecuta. Kodavio no lleva librería de PDF a propósito. Si no hay Chromium/weasyprint/wkhtmltopdf en el entorno, la skill entrega el HTML y lo dice.
- Requiere plugin Kodavio 0.3 para `kodavio/report-get-branding`. Con versiones anteriores la skill sigue valiendo: firma el informe con el nombre del sitio. Sin migración necesaria.

## 2026-07-02

### Añadido
- **Regla `rules/execution-profile.md`** — disciplina de escritura por perfil de ejecución (Rápido/Equilibrado/Seguro), alineada con Kodavio 0.1.9. El plugin devuelve el contrato vinculante en `kodavio/context-bootstrap` (`execution_profile.contract`) y funciona **sin el kit**; esta regla explica cómo aplicarlo y su precedencia: el perfil nunca rebaja los guardarraíles de entorno (producción = drafts + gate + dry-run siempre).

### Cambiado
- `rules/kodavio-protocol.md` (pasos 2/6/7), `skills/wp-site-session/SKILL.md`, `skills/wp-page-build/SKILL.md`, `skills/wp-content-publish/SKILL.md`, `skills/wp-builder-convert/SKILL.md`: cablean el `execution_profile` del bootstrap a la disciplina de dry-run/verify/read-before-write. También se menciona el snapshot `preferences[]` per-site que ahora devuelve el bootstrap (Kodavio 0.1.9 #4). Sin migración necesaria.

### Notas
- Requiere plugin Kodavio 0.1.9 para que el bootstrap devuelva `execution_profile` y `preferences[]`; con 0.1.8 las skills degradan a la disciplina por defecto (Equilibrado). Cambios de markdown puro, sin release del plugin para usarse.

## 2026-06-26

### Cambiado
- **Orden canónico de llamadas alineado con plugin Kodavio 0.1.8**: ahora `kodavio/workflow-router` → **`kodavio/context-bootstrap`** → `kodavio/skill-get`. El bootstrap recupera scope + sistema de diseño activo + memoria vinculante + últimos cambios en una sola llamada (sustituye a llamar a `scope-read`, `design-read` y `memory-list` por separado). Cualquier entry de memoria con `source=human` + `tag=instruction|caveat` es **vinculante** durante toda la sesión. Antes de cualquier write destructivo, re-revisar `kodavio/memory-list tag=caveat`. Al cerrar la sesión, escribir decisiones load-bearing con `kodavio/memory-write source=agent`. Archivos actualizados: `AGENTS.md`, `rules/kodavio-protocol.md`, `workflows/WORKFLOWS.md`, `skills/wp-site-session/SKILL.md`, `skills/wp-page-build/SKILL.md`. Sin migración necesaria.

### Añadido
- **Skill `wp-copywriting`** — copy comercial de WordPress (landing, home, página de servicio, sobre nosotros, FAQ) en castellano perfecto, anclado al scope del sitio y al sistema de diseño activo. Cubre la voz comercial; el editorial sigue siendo `wp-content-publish`.
- **Skill `wp-marketing`** — plan de marketing digital sobre WordPress: diagnóstico del cuello de botella del embudo, plan accionable de captación/conversión/nutrición, integración con FluentCRM/FluentForms/WooCommerce. Genera lista de tareas concretas para el agente operativo, no campañas creativas.
- **Skill `wp-patterns-author`** — asistente para crear patterns propios para el catálogo de Kodavio (disponible desde el plugin 0.1.8 con la nueva pestaña `Kodavio › Diseño y memoria › Patterns`). Cubre anatomía del spec, tipos de nodos, roles vs literales, plantillas por categoría (hero, CTA, features, pricing, testimonial, FAQ), validación previa, packs import/export entre sitios.
- **Skill `wp-security-cleanup`** — respuesta a incidente de seguridad. Orquesta el MCP propio `wp-malware-cleanup-mcp` (escaneos, cleanup, hardening) junto con las abilities Kodavio de auditoría (admins, change log, plugins/themes) y los human gates del kit. Protocolo en 5 fases con confirmación humana explícita por acción destructiva. Distinto de `wp-security-triage`, que cubre hardening proactivo de un sitio limpio.

### Notas
- Las 4 skills nuevas son markdown puro (formato SKILL.md estándar). No necesitan release del plugin para usarse.
- El plugin 0.1.8 (memoria + pestaña Patterns) y este corte del kit están diseñados para trabajar juntos: probarlos en bloque.

## 2026-06-12

### Añadido
- **Credenciales sin texto plano** (`docs/credentials.md` + `scripts/wp-mcp-launch.sh|.ps1`): lanzador multiplataforma que lee la Application Password del almacén de secretos del SO (Keychain / libsecret / `pass` / Credential Manager / python-keyring) y la inyecta al proxy en el arranque — los archivos de config del agente dejan de contener secretos en macOS, Linux y Windows.
- **Soporte Kilo Code**: Kilo lee `AGENTS.md` y las skills (`.claude/skills/`, estándar Agent Skills) sin configuración. Plantilla MCP (`kilo.jsonc`) en `docs/mcp-config-examples.md`; `kilo.jsonc`/`.kilo/` en `.gitignore`.
- `sites/_template/PLAN.md`: plantilla de la cola de briefs que crea `wp-site-plan`.
- Este CHANGELOG (el README lo prometía para migraciones de esquema).

### Cambiado
- Proxy MCP **pineado a `@automattic/mcp-wordpress-remote@0.3.4`** en todas las plantillas y en `add-site.sh` (antes `@latest`: ese proceso recibe credenciales de los sitios; las subidas de versión se hacen a conciencia). *Recomendado actualizar los servers MCP ya registrados con `@latest` en tu herramienta.*
- `add-site.sh`: el slug por defecto respeta la convención de sufijos (`staging.example.com` → `example_com_staging`); acepta `http://` solo para desarrollo local; mensaje honesto en 401/403 (endpoint protegido ≠ Kodavio confirmado); sin líneas en blanco acumuladas al final de `sites.json`; cabecera aclara dónde acaban las credenciales con `claude mcp add`.
- `agents/wp-auditor.md`: eliminada la whitelist `tools:` — bloqueaba TODAS las herramientas MCP de Kodavio (verificado en vivo: el auditor no podía auditar). El read-only se garantiza por prompt, como en `wp-verifier`.
- `wp-onboard-site`: instalar Kodavio en producción pide confirmación explícita (el contexto del alta no aprueba el gate solo).
- Referencias a la capa SA (`Playbook/*`, skills globales `market-seo`) marcadas como opcionales para cloners.
- README: requisitos completos (python3, symlinks en Windows), conteo real de subagentes (10).

### Sin migración local
Ningún cambio de esquema en `sites.example.json`.

## 2026-06-10

- v1 inicial: AGENTS.md + punteros multi-agente, registro de sitios, 3 reglas duras, 12 skills, 10 subagentes, WORKFLOWS.md, onboarding interactivo (`/wp-onboard-site`) y por terminal (`add-site.sh`).
