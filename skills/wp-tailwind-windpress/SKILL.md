---
name: wp-tailwind-windpress
description: Trabajar con Tailwind CSS v4 en WordPress vía WindPress - detección, configuración, reglas de uso de utilities y convivencia con Bricks/FDS. Usar cuando el sitio tenga WindPress o la tarea pida utilidades Tailwind.
---

# wp-tailwind-windpress — Tailwind en WordPress

> ⚠️ **WindPress compila Tailwind en el navegador**: no hay recompilación desde PHP. Un cambio de tokens o de config escrito por MCP no existe en el CSS servido hasta que alguien abra WindPress y genere, o hasta que se suba la caché compilada fuera del sitio (Kodavio 0.3.2, paso 6 de abajo). Aplica `rules/render-verification.md` — si no se ve, no está hecho, y tu reporte lo dice.

> Recorre las fases canónicas (`rules/skill-phases.md`) y ejecuta por **rol**, prefiriendo la ability nativa cuando exista, envuelta en el gate de Kodavio (`rules/ability-source-agnostic.md`).

## Detección (siempre primero)

1. `kodavio/windpress-detect` → ¿el sitio tiene WindPress activo?
2. Si sí: `kodavio/windpress-read-config` → versión TW, entry points, qué archivos escanea.
3. Si **no** hay WindPress: **no escribas clases Tailwind** — no compilarán. Usa clases globales del builder y tokens del design system (`wp-bricks-fds` para Bricks). Instalar WindPress es decisión del humano (plugin nuevo = gate en producción).

## Modelo mental

WindPress compila Tailwind v4 **dentro de WordPress**: escanea el contenido (árboles del builder incluidos) y genera el CSS. No hay node en el server. Consecuencias:

- Las clases escritas en elementos Bricks/Gutenberg sí se compilan (si el scanner las ve).
- Clases generadas dinámicamente (concatenadas en runtime) NO se detectan → no existirán en el CSS.
- Cambios de config/tokens → recompilar (paso 6 de *Cambiar tokens del sistema*) y verificar en frontend.

## Reglas de uso

1. **Utilities estándar, cero valores arbitrarios.** Nada de `bg-[#a1b2c3]`, `opacity-[0.04]`, `w-[37px]`. Si Tailwind no lo cubre con un token existente: o se simplifica, o se crea una clase semántica en el CSS del sistema (vía flujo `design_system`), nunca un arbitrary inline.
2. **Tokens antes que utilities crudas.** Si el sitio tiene FDS u otro design system con clases semánticas (`.heading`, `.btn-primary`, `--spacing-section`), esas mandan; Tailwind rellena los huecos (flex, grid, gap, hidden…), no sustituye al sistema.
3. **Clases en el elemento, no `<style>`.** Cero CSS inline en code widgets para lo que una utility resuelve.
4. **Clases repetidas = clase global.** Si la misma combinación aparece en 3+ elementos, va a una clase global del builder o a una clase de componente del sistema, no copy-paste de utilities.
5. **Dark mode / estados**: usar las variantes estándar (`hover:`, `md:`, `dark:` si el sitio lo soporta). Comprobar en `windpress-read-config` qué variantes están habilitadas antes de usarlas.

## Convivencia con Bricks

- Las utilities van en el campo de clases CSS del elemento Bricks (o clase global), nunca incrustadas en HTML dentro de un nodo de texto.
- Layout estructural: elementos `div` con su etiqueta semántica y las clases de layout del design system (regla 1 de `wp-bricks-fds`: nada de elementos `section`/`container`/`block`); Tailwind para ajustes finos.
- Tras escribir: verificar en frontend que las clases nuevas compilaron (estilo aplicado, no solo presente en el DOM). Clase sin efecto = scanner no la vio → revisar config de WindPress.

## Cambiar tokens del sistema: la cadena FDS → WindPress

Un token (color, tipografía, spacing…) no se cambia editando ficheros de WindPress: recorre una cadena, y la última milla es compilar. Pasos 1-5 y el *Generate* humano, verificados de punta a punta en la fase 5 de `projects/kodavio/scripts/verify-bricks-battery.sh` (Bricks 2.4, 2026-09-17). Cada paso con su `dry_run` primero y su gate según entorno (`rules/production-guardrails.md`).

1. **Leer lo que hay.** `kodavio/design-get-tokens` (`group`) y `kodavio/windpress-read-config` (`include_values=true`): tokens actuales de la memoria de diseño y ficheros de tokens de WindPress.
2. **Escribir el token en la memoria de diseño**, que es el origen: `kodavio/design-set-tokens` (`group`, `tokens`, `dry_run`). Nunca directamente en el CSS de WindPress.
3. **Comprobar que el FDS lo traduce.** `kodavio/fds-export-config`: el token tiene que aparecer en la config de Tailwind que exporta.
4. **Sincronizar con WindPress.** `kodavio/windpress-sync-design-system` con `dry_run=true`, leer la salida, y después `dry_run=false` + `confirm_write=true`. Por defecto **fusiona en el fichero de tokens que el sitio ya tiene**, con copia previa; no crea ficheros nuevos.
   - Si el sitio **no tiene sistema de tokens** en WindPress, la sincronización falla y el error sugiere `force_new_theme=true`: crea un `kodavio-theme.css` con su import. Úsalo solo con aprobación: da de alta el sistema de diseño en ese sitio.
5. **Read-back.** `kodavio/windpress-read-config` con `include_values=true`: el valor nuevo tiene que estar en `files[].preview` del fichero de tokens (`uploads/windpress/data/`). Si no está, la cadena se cortó aquí: no sigas.
6. **Compilar.** `kodavio/windpress-cache-action` con `action=build` sigue sin compilar: WindPress compila en el navegador. Dos caminos:
   - **Humano**: abrir WindPress en wp-admin y pulsar **Generate**. Es el que ve todas las clases.
   - **Desde el agente** (Kodavio 0.3.2): pedir a Kodavio las clases que usa el sitio y el `main.css`, compilar con Tailwind en tu máquina y subir la caché, con ensayo, copia de la anterior y confirmación doble. Cambia el CSS de **todo el sitio**: en producción es GATE. Compilar fuera puede dejar fuera alguna clase que WindPress sí habría visto. Las capacidades y el orden exacto: `kodavio/agent-handbook`.
   - **Nunca purgar** la caché de WindPress salvo que el humano lo pida.
7. **Si no se ha compilado, repórtalo en primera línea** (`rules/render-verification.md`): *«El token está en el fichero de WindPress; falta abrir WindPress › Generate (o subir la caché) para que llegue a la web.»* La tarea queda pendiente, no hecha.
8. **Verificar en lo servido, después de compilar.** El valor tiene que estar en `/wp-content/uploads/windpress/cache/tailwind.css` y aplicarse en una página. Si subiste la caché, comprueba además que no ha desaparecido ningún estilo que antes se veía; si falta alguno, deshaz la subida (`kodavio/rollback`) o genera desde WindPress. Solo entonces está hecho.

Para comprobar si unas utilities existen antes de usarlas en elementos: `kodavio/windpress-verify-utilities` (`classes`).

## Cuándo NO usar esta skill

- Sitio sin WindPress ni Tailwind → estilos del builder + design system.
- Cambios de tokens/colores globales → no con utilities sueltas: sección *Cambiar tokens del sistema* de arriba (flujo `design_system`, playbook de servidor `design-frameworks`).
- Maquetar páginas enteras a base de utilities cuando existe FDS → usar `wp-bricks-fds`.
