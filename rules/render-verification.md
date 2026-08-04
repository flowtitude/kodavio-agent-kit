# Regla dura — Escrito ≠ visible

> Un write puede **triunfar en el dato y no existir para el usuario**. La ability devuelve `ok`, el read-back coincide, el árbol está perfecto… y el humano abre la página y no ve el cambio. Esta regla cierra ese hueco: **la verificación no termina en la capa de datos, termina en la superficie renderizada.**
>
> Complementa el invariante 4 de `production-guardrails.md` (verificación post-write). Aquel dice *verifica que se escribió*; este dice *verifica que se ve*.

## Por qué existe

Lo que el usuario ve casi nunca es el dato que escribiste. Entre medias hay un artefacto **compilado o cacheado** que vive en otro sitio y que **tu write no regenera**:

| Integración | Dónde vive lo que se ve | Quién lo regenera |
|---|---|---|
| **Elementor** | CSS compilado en `uploads/elementor/css/post-<id>.css` | Solo un Guardar/Update en el editor, o Tools › Regenerate CSS. **Ni el toggle draft→publish** |
| **WindPress / Tailwind** | CSS que WindPress compila **en el navegador** | Alguien tiene que abrir WindPress; no hay recompilación desde PHP |
| **Bricks** | CSS regenerado por el Save_Pipeline | La escritura delegada a la ability nativa 2.4 lo hereda; otros caminos, no siempre |
| **Cualquiera** | Caché de objetos, de página, CDN | Purga explícita |

Los dos primeros están **verificados en vivo** (`docs/field-notes.md`, `docs/kodavio-gaps-elementor.md`). No son hipótesis.

## La regla

1. **Si el cambio afecta a lo que se ve, la verificación incluye mirar la superficie renderizada**: la URL de preview o del frontend, no solo el read-back del árbol. Contenido y estilo se verifican por separado — el contenido suele aparecer aunque el estilo no.
2. **Si el render no se puede regenerar por MCP, el trabajo NO está terminado**: está *pendiente de un paso humano*. Eso va en el reporte, en primera línea y en concreto («abre la plantilla en Elementor y dale a Update, si no el estilo no se ve»), no como nota al pie.
3. **Nunca declares PASS por un read-back limpio** cuando la integración es de las de la tabla. Un read-back limpio con estilo invisible es exactamente el falso PASS que esta regla existe para impedir.
4. **Si no puedes mirar el render** (sin preview, sin acceso al frontend), dilo. «No he podido verificar el render» es un resultado honesto; «hecho» no lo es.

## Cómo se comprueba

- Pide la URL de preview o del frontend y **mírala** (WebFetch, captura, o el propio humano).
- Compara contra lo que pedía el brief: ¿está el espaciado? ¿el color? ¿el grid responde? Si el contenido está pero el estilo no, ya sabes dónde estás: en el CSS compilado.
- Si el sitio tiene caché o CDN, purga o añade un cache-buster antes de concluir. Un 200 con HTML viejo no prueba nada.

## Qué escribir en el reporte

```
Escrito y verificado en datos: sí (read-back OK, 6 secciones, 41 nodos).
Visible para el usuario: NO todavía — el estilo vive en el CSS compilado de
Elementor y no se regenera por MCP.
Acción humana requerida: abrir la plantilla en el editor y dar Update
(o Elementor › Tools › Regenerate CSS). Sin eso, la página se ve sin estilos.
```

## En una línea

El dato correcto no es el trabajo terminado. **Si no se ve, no está hecho** — y si no puede verse sin una mano humana, tu reporte lo dice antes que ninguna otra cosa.
