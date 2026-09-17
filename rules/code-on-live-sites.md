# Regla dura — Código en sitios en vivo

> Dónde puede vivir el código que escribe un agente en un WordPress real. Objetivo: que todo lo que haga la IA sea **contenible, identificable y reversible**.

## Jerarquía de ubicaciones (de preferida a prohibida)

1. **Gestor de snippets del sitio** — `kodavio/wp-write-snippet` escribe en **FluentSnippets, Code Snippets o WPCode**, el que tenga el sitio (`kodavio/wp-detect-snippet-manager` dice cuál). Es la superficie preferida: cada snippet se desactiva desde wp-admin sin FTP, y **Kodavio lo desactiva solo** si tras escribir la portada o la API REST dejan de responder. Verificado en WordPress real con los tres el 2026-09-17.
2. **Sandbox Kodavio** — `wp-content/kodavio-sandbox/*.php`, vía `kodavio/wp-write-code-file`. Recuperable sin FTP, con safe mode y crash marker (`kodavio/wp-sandbox-status`, `wp-sandbox-clear-crash`). Si el sitio no tiene gestor de snippets, y para todo lo experimental.
3. **MU-plugin — último recurso** — vía `kodavio/wp-write-mu-plugin` + `wp-validate-mu-plugin`, que vienen **apagadas por defecto** (permiso aparte en Kodavio › Herramientas). Solo si el código tiene que cargar antes que los plugins. Se carga en cada petición: si rompe algo que la comprobación no ve, se recupera por FTP. Un archivo, una responsabilidad, prefijo `sa-`.
4. **Plugin propio versionado** — si la funcionalidad crece, se convierte en plugin con repo git. Ya no se edita en vivo: se desarrolla local y se despliega.
5. **Tema/plugin activo** — ❌ prohibido editar salvo orden explícita del humano + gate + backup. NUNCA functions.php del tema activo como cajón de sastre.
   - **Excepción `theme.json`**: solo si el tema activo es **child theme**, y siempre vía `kodavio/design-source-update` o `kodavio/design-source-patch` con `provider=gutenberg` (nunca por FS directo). Si el tema activo es **parent sin child**, el `theme.json` se sobrescribirá en cada update del tema → crear child antes de escribir o trasladar al sistema de design tokens correspondiente (WindPress/Bricks/ACSS).
6. **Core de WordPress** — ❌ prohibido siempre.

> Por qué este orden: *Kodavio debe poder deshacer, por su propio canal, cualquier cosa que haga* (`projects/kodavio/docs/design/safe-customization-and-reversibility.md`). Toda escritura de código comprueba después la portada **y la API REST** —el canal de Kodavio— y la revierte si alguna da 5xx.

## Rutas prohibidas por filesystem (todo entorno, sin gate posible)

NUNCA se editan con `wp-write-*` ni `file_put_contents`. Editarlas por FS deja el sitio sin recompilar (WindPress compila en navegador, no en PHP) o reemplazable por update del tema, y rompe el design system sin posibilidad de rollback consistente:

- `wp-config.php`, `.htaccess`, `robots.txt`
- `theme.json` del tema **padre** o activo (la versión child va por design-source provider=gutenberg, ver excepción arriba)
- `tailwind.config.js` y ficheros de configuración de WindPress (`wp-content/uploads/windpress/data/...`)
- `main.css` y cualquier `@theme`/`@import` resuelto por WindPress
- Stores override de ACSS / Core Framework

## Design sources: vía abilities, nunca filesystem

Toda escritura sobre el sistema de diseño pasa por su ability (con `dry_run`, backup y, en WindPress, respetando el pipeline de compilación):

- **Tailwind / WindPress** → `kodavio/windpress-*` (`detect`, `read-config`, `sync-design-system`, `cache-action`) y/o `kodavio/design-source-*` con `provider=windpress`.
- **theme.json** → `kodavio/design-source-*` con `provider=gutenberg`.
- **ACSS / Core Framework** → `kodavio/design-source-*` con `provider=framework-overrides` o `kodavio/design-apply-active-system`.
- **Bricks global classes / tokens** → `kodavio/design-source-*` con `provider=bricks`.
- **Elementor Kit (system colors / typography)** → `kodavio/design-source-*` con `provider=elementor` *(Elementor aparcado en Kodavio desde el 2026-08-12)*.

La edición directa de los archivos subyacentes está prohibida igual que tocar `wp-config.php`.

## Requisitos de cualquier write de código

- Lint ANTES del write (si `php_lint_available=false` en el config summary → **no escribir PHP en ese sitio**; queda anotado como caveat en `registry/sites.json`).
- Backup ID devuelto y anotado.
- Patch mínimo: `wp-patch-code-file` antes que reescritura completa.
- Cabecera con marca de origen: `/* sa-agent: {fecha} {tarea} */` para poder auditar qué escribió la IA.
- Plan de rollback en una línea en la respuesta final.

## CSS

CSS sigue `Playbook/rules/css-workflow.md` (capa SA — si esa ruta no existe en tu entorno, omítela y aplica lo que sigue). En sitios Bricks: clases globales y design tokens del sistema activo, no estilos inline por elemento. Cambios de tokens = flujo `design_system`, no ediciones sueltas.

Para Tailwind / WindPress / `theme.json`: ver **Design sources** arriba — nunca `file_put_contents`.
