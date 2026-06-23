# Workflows — petición → flujo Kodavio → skill local → agentes → gates

> Tabla de enrutado. En caso de duda, `kodavio/workflow-router` del sitio decide el flujo primario.
> Orden de dependencia para flujos compuestos: diagnóstico → admin → design system → content model → mini plugin → página → migración.

| Petición típica | Flujo Kodavio | Skill local | Subagentes | Gates en producción |
|---|---|---|---|---|
| "¿Cómo está el sitio X?" / informe / análisis previo | `diagnostic_audit` | `wp-site-health` (parte auditoría) | wp-auditor | ninguno (read-only) |
| "Hazme la web" / sitio nuevo / rediseño completo | — (plan) → flujos en orden | `wp-site-plan` → cola de briefs | wp-content-architect → builder-operator del builder → wp-verifier | aprobar plan; publicar = gate |
| Mantenimiento: updates, limpieza, ajustes | `wordpress_admin` | `wp-site-health` | wp-operator + wp-verifier | updates/limpieza = gate + log |
| Crear/editar página, sección, template, componente | `page_creation` | `wp-page-build` (+ `wp-design-patterns` en autoría) | wp-bricks/elementor/gutenberg-operator + wp-verifier | publicar = gate |
| "Hazla como esta captura/mockup" | `page_creation` | `wp-reference-to-brief` → `wp-page-build` | builder-operator del builder + wp-verifier | publicar = gate |
| Posts, contenido editorial, SEO on-page | `page_creation` (light) o CRUD | `wp-content-publish` | wp-content-writer | publicar = gate |
| Tokens, paleta, sistema de diseño, frameworks | `design_system` | `wp-bricks-fds` / `wp-tailwind-windpress` (+ playbooks servidor `design-frameworks`, `flowtitude-design-scope`) | builder-operator + wp-verifier | aplicar sistema activo = gate |
| CPTs, campos, ACF/JetEngine, loops, dynamic data | `content_model_dynamic` | — (playbooks servidor `content-model-schema`, `dynamic-data-binding`, `acf-integration`, `jetengine-integration`) | wp-content-architect + builder-operator + wp-verifier | migrar datos existentes = gate |
| Snippet, shortcode, hook, endpoint, mu-plugin | `mini_plugin` | — + regla `code-on-live-sites.md` | wp-operator + wp-verifier | SIEMPRE gate en producción |
| Migrar builder (E↔B↔G) o framework | `builder_migration` | `wp-builder-convert` | wp-auditor → builder-operator destino → wp-verifier | cutover y borrado de original = gate |
| WooCommerce: productos, pedidos, cupones | `wordpress_admin` | — (playbook servidor `woocommerce-operations`) | wp-woo-operator | pedidos/refunds/precios = gate (dinero) |
| Fluent (CRM, forms, support, booking) | `wordpress_admin` | — (playbook servidor `fluent-suite` + MCPs fluent-*) | wp-operator | campañas/emails salientes = gate (comunicación externa) |
| Sospecha de hackeo / hardening | — (mínimo Kodavio) | `wp-security-triage` | wp-auditor + wp-operator | borrar/rotar credenciales = gate |
| Sitio nuevo a conectar | — | `wp-onboard-site` (comando interactivo) o `scripts/add-site.sh` | — | instalar plugin en prod = gate |

## Cadena estándar de una tarea de escritura

```
wp-site-session → workflow-router → skill-get (playbook) → AUTORÍA (brief/copy/payload)
→ dry_run → [GATE si aplica] → write → wp-verifier → NOTAS.md + OPS
```

### Contrato de cierre

Una sesión **NO puede declarar PASS** sobre un write en producción sin output explícito de `wp-verifier` registrado en `sites/{slug}/NOTAS.md` (sección **Verificación** con timestamp + IDs read-back + veredicto PASS / PASS-avisos / FAIL).

Si trabaja un solo agente, debe ejecutar el protocolo `wp-verifier` como **pase separado** (otra invocación, no en la misma respuesta del write) antes del cierre. Sin ese registro, la tarea queda `in_progress` y no se cierra.

## Cuándo lanzar subagentes vs hacerlo el principal

- Tarea corta de un solo dominio → el agente principal con el playbook cargado basta.
- Página grande, lote de contenido, conversión multi-página → subagentes por rol (autoría / operación / verificación separadas).
- Verificación: SIEMPRE separada de la mano que escribió cuando el cambio toca producción o una conversión (el que escribe no se autoaprueba).

## Casos compuestos (ejemplos)

- **Landing con loop de CPT nuevo**: `content_model_dynamic` (CPT+campos+query) → `page_creation` (página con bindings). Nunca al revés.
- **Rediseño con framework nuevo**: `design_system` (tokens) → `page_creation` (páginas usando tokens). No editar páginas con estilos sueltos "mientras tanto".
- **Snippet que añade endpoint para una página**: `mini_plugin` (sandbox+verify) → `page_creation`.
