# Regla dura — Código en sitios en vivo

> Dónde puede vivir el código que escribe un agente en un WordPress real. Objetivo: que todo lo que haga la IA sea **contenible, identificable y reversible**.

## Jerarquía de ubicaciones (de preferida a prohibida)

1. **Sandbox Kodavio** — `wp-content/kodavio-sandbox/*.php`. Recuperable, con safe mode y crash marker (`kodavio/wp-sandbox-status`, `wp-sandbox-clear-crash`). Para todo lo experimental.
2. **MU-plugin controlado** — vía `kodavio/wp-write-mu-plugin` + `wp-validate-mu-plugin`. Para funcionalidad estable y pequeña. Un archivo, una responsabilidad, prefijo `sa-`.
3. **Plugin de snippets** (FluentSnippets o equivalente si el sitio lo tiene) — alternativa válida al MU-plugin: cada snippet desactivable desde el admin sin tocar FS.
4. **Plugin propio versionado** — si la funcionalidad crece, se convierte en plugin con repo git. Ya no se edita en vivo: se desarrolla local y se despliega.
5. **Tema/plugin activo** — ❌ prohibido editar salvo orden explícita del humano + gate + backup. NUNCA functions.php del tema activo como cajón de sastre.
6. **Core de WordPress** — ❌ prohibido siempre.

## Requisitos de cualquier write de código

- Lint ANTES del write (si `php_lint_available=false` en el config summary → **no escribir PHP en ese sitio**; queda anotado como caveat en `registry/sites.json`).
- Backup ID devuelto y anotado.
- Patch mínimo: `wp-patch-code-file` antes que reescritura completa.
- Cabecera con marca de origen: `/* sa-agent: {fecha} {tarea} */` para poder auditar qué escribió la IA.
- Plan de rollback en una línea en la respuesta final.

## CSS

CSS sigue `Playbook/rules/css-workflow.md`. En sitios Bricks: clases globales y design tokens del sistema activo, no estilos inline por elemento. Cambios de tokens = flujo `design_system`, no ediciones sueltas.
