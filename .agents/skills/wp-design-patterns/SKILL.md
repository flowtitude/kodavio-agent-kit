---
name: wp-design-patterns
description: Patrones de diseño para componer páginas WordPress con criterio - anatomía de sección, ritmo de página, jerarquía, y catálogo de secciones (hero, features, pricing, FAQ, CTA, social proof). Usar en la fase de autoría de wp-page-build, antes de escribir en el builder.
---

# wp-design-patterns — Patrones de composición

Esta skill alimenta la **Fase 1 (autoría)** de `wp-page-build`: cómo decidir estructura y jerarquía antes de tocar Kodavio. Si el sitio usa FDS/Bricks → combinar con `wp-bricks-fds` (clases y elementos concretos).

## Principios

1. **Leer antes de diseñar**: `kodavio/design-read` (lenguaje visual del sitio) + 2-3 páginas existentes. Una página nueva debe parecer del mismo sitio, no un tema demo.
2. **Una idea por sección.** Si una sección cuenta dos cosas, son dos secciones.
3. **Jerarquía**: 1 H1 por página; el tamaño visual decrece con la profundidad; el eyebrow/kicker no sustituye al heading.
4. **Ritmo**: alternar densidad (sección llena → sección de aire), fondo (claro/oscuro/acento) y alineación (centrado/izquierda) para que el scroll respire. Tres secciones seguidas idénticas = monotonía.
5. **Una CTA primaria por pantalla.** Las secundarias, visualmente subordinadas (outline/link).
6. **Responsive intent declarado**: para cada sección, decidir qué pasa en móvil (apilar, ocultar, reordenar) ANTES de construirla, no después.
7. **Contenido real.** Sin lorem ipsum: si falta copy, se redacta primero (`wp-content-publish` / wp-content-writer).

## Catálogo de secciones

| Patrón | Anatomía | Cuándo | Errores típicos |
|---|---|---|---|
| **Hero** | eyebrow + H1 (beneficio, no nombre) + subtítulo + CTA primaria (+ secundaria) + visual | Apertura de página | H1 genérico ("Bienvenidos"); 2 CTAs del mismo peso; imagen que aplasta el LCP |
| **Logos / trust bar** | 4-8 logos monocromos en fila | Justo tras el hero si hay clientes reconocibles | Logos a color que compiten; carrusel innecesario |
| **Features (grid)** | H2 + 3/6 cards (icono + título + 1-2 líneas) | Capacidades del producto/servicio | Más de 6 items; párrafos largos en cards |
| **Feature destacada (zigzag)** | Filas alternas imagen↔texto, cada una con mini-heading + texto + link | Profundizar en 2-4 features clave | No alternar lados; imágenes decorativas que no muestran nada |
| **Social proof** | Quote + nombre + cargo + foto/logo; 1 grande o grid de 3 | Tras features o antes de pricing | Testimonios anónimos; carruseles automáticos |
| **Pricing** | 2-4 planes, el recomendado destacado; precio + frecuencia + bullets + CTA por plan | Páginas de venta | Tablas de 20 filas; sin plan destacado |
| **FAQ** | H2 + acordeón/lista de 5-8 preguntas reales | Pre-cierre; objeciones de compra | Preguntas inventadas de relleno; respuestas-ensayo |
| **CTA final** | H2 directo + 1 botón (+ micro-claim de confianza) | Cierre de toda página comercial | Repetir el hero literal; meter un formulario entero si basta un botón |
| **Stats** | 3-4 cifras grandes + etiqueta corta | Credibilidad con datos reales | Cifras no verificables; decimales irrelevantes |
| **Steps / proceso** | 3-5 pasos numerados, lineales | Servicios, onboarding | Más de 5 pasos; pasos sin verbo |

## Plantillas de página (composición completa)

- **Landing comercial**: Hero → Trust bar → Features grid → Zigzag (2-3) → Social proof → Pricing → FAQ → CTA final.
- **Página de servicio**: Hero → Problema/solución → Steps → Features → Social proof → CTA.
- **Home corporativa**: Hero → Qué hacemos (features) → Prueba social → Servicios destacados → CTA contacto.
- **About**: Hero bajo → Historia (zigzag) → Equipo (grid) → Valores → CTA.

Son puntos de partida: el brief manda, y el orden se ajusta al argumento de venta, no al revés.

## Entregable de esta fase

Brief de página listo para `wp-page-build` Fase 2: lista ordenada de secciones, cada una con patrón, copy real, CTA y comportamiento responsive. Con eso, el builder-operator no tiene que decidir nada creativo.
