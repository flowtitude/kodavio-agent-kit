---
name: wp-tailwind-windpress
description: Trabajar con Tailwind CSS v4 en WordPress vía WindPress - detección, configuración, reglas de uso de utilities y convivencia con Bricks/FDS. Usar cuando el sitio tenga WindPress o la tarea pida utilidades Tailwind.
---

# wp-tailwind-windpress — Tailwind en WordPress

> ⚠️ **WindPress compila Tailwind en el navegador**: no hay recompilación desde PHP. Un cambio de tokens o de config escrito por MCP puede no existir en el CSS servido hasta que alguien abra WindPress. Aplica `rules/render-verification.md` — si no se ve, no está hecho, y tu reporte lo dice.

> Recorre las fases canónicas (`rules/skill-phases.md`) y ejecuta por **rol**, prefiriendo la ability nativa cuando exista, envuelta en el gate de Kodavio (`rules/ability-source-agnostic.md`).

## Detección (siempre primero)

1. `kodavio/windpress-detect` → ¿el sitio tiene WindPress activo?
2. Si sí: `kodavio/windpress-read-config` → versión TW, entry points, qué archivos escanea.
3. Si **no** hay WindPress: **no escribas clases Tailwind** — no compilarán. Usa clases globales del builder y tokens del design system (`wp-bricks-fds` para Bricks). Instalar WindPress es decisión del humano (plugin nuevo = gate en producción).

## Modelo mental

WindPress compila Tailwind v4 **dentro de WordPress**: escanea el contenido (árboles del builder incluidos) y genera el CSS. No hay build local ni node en el server. Consecuencias:

- Las clases escritas en elementos Bricks/Gutenberg sí se compilan (si el scanner las ve).
- Clases generadas dinámicamente (concatenadas en runtime) NO se detectan → no existirán en el CSS.
- Cambios de config/tokens → recompilar desde WindPress y verificar en frontend.

## Reglas de uso

1. **Utilities estándar, cero valores arbitrarios.** Nada de `bg-[#a1b2c3]`, `opacity-[0.04]`, `w-[37px]`. Si Tailwind no lo cubre con un token existente: o se simplifica, o se crea una clase semántica en el CSS del sistema (vía flujo `design_system`), nunca un arbitrary inline.
2. **Tokens antes que utilities crudas.** Si el sitio tiene FDS u otro design system con clases semánticas (`.heading`, `.btn-primary`, `--spacing-section`), esas mandan; Tailwind rellena los huecos (flex, grid, gap, hidden…), no sustituye al sistema.
3. **Clases en el elemento, no `<style>`.** Cero CSS inline en code widgets para lo que una utility resuelve.
4. **Clases repetidas = clase global.** Si la misma combinación aparece en 3+ elementos, va a una clase global del builder o a una clase de componente del sistema, no copy-paste de utilities.
5. **Dark mode / estados**: usar las variantes estándar (`hover:`, `md:`, `dark:` si el sitio lo soporta). Comprobar en `windpress-read-config` qué variantes están habilitadas antes de usarlas.

## Convivencia con Bricks

- Las utilities van en el campo de clases CSS del elemento Bricks (o clase global), nunca incrustadas en HTML dentro de un nodo de texto.
- Layout estructural (section/container/grid): preferir los controles nativos de Bricks o las clases de layout del design system; Tailwind para ajustes finos.
- Tras escribir: verificar en frontend que las clases nuevas compilaron (estilo aplicado, no solo presente en el DOM). Clase sin efecto = scanner no la vio → revisar config de WindPress.

## Cuándo NO usar esta skill

- Sitio sin WindPress ni Tailwind → estilos del builder + design system.
- Cambios de tokens/colores globales → eso es flujo `design_system` (playbook `design-frameworks`), no utilities sueltas.
- Maquetar páginas enteras a base de utilities cuando existe FDS → usar `wp-bricks-fds`.
