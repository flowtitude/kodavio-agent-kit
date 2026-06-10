# Kodavio Agent Kit

Workspace clonable para operar **instalaciones WordPress en vivo con agentes de IA** (Claude Code, Cursor, Codex, OpenCode) a través del plugin **[Kodavio](https://flowtitude.com)**.

Kodavio convierte cada WordPress en un servidor MCP con abilities seguras para builders (Bricks, Elementor, Gutenberg), diseño, conversión, contenido dinámico y administración. Este kit es la **capa cliente** que le falta a tu máquina: registro de sitios, guardarraíles por entorno, protocolo de trabajo, skills de orquestación y subagentes — todo en markdown portable, sin lock-in a ninguna herramienta.

```
┌─────────────────────────────┐         ┌──────────────────────────────┐
│  TU MÁQUINA (este kit)      │   MCP   │  CADA WORDPRESS (Kodavio)    │
│  qué, dónde, con qué        │ ──────▶ │  cómo ejecutar:              │
│  permisos:                  │  HTTPS  │  · abilities builder/admin   │
│  · registry de sitios       │         │  · playbooks (skill-get)     │
│  · guardarraíles por entorno│         │  · workflow-router           │
│  · skills + subagentes      │         │  · dry-run, backups, verify  │
│  · memoria por sitio        │         │  · design memory, scope      │
└─────────────────────────────┘         └──────────────────────────────┘
```

**Principio rector:** el agente es el autor (copy, jerarquía, dirección de diseño), Kodavio es el ejecutor, y el humano aprueba lo irreversible.

---

## Índice

1. [Requisitos](#requisitos)
2. [Instalación](#instalación)
3. [Actualizar la instalación global del agente](#actualizar-la-instalación-global-del-agente)
4. [Onboarding: conectar tu primer sitio](#onboarding-conectar-tu-primer-sitio)
5. [Uso diario](#uso-diario)
6. [Capacidades](#capacidades)
7. [Seguridad y datos](#seguridad-y-datos)
8. [Estructura del repo](#estructura-del-repo)
9. [Multi-agente](#multi-agente)
10. [Mantener el kit al día](#mantener-el-kit-al-día)

---

## Requisitos

- **Un agente de IA** con soporte MCP: Claude Code (recomendado), Cursor, Codex u OpenCode.
- **Node.js ≥ 18** (el proxy MCP `@automattic/mcp-wordpress-remote` corre con `npx`).
- **Plugin Kodavio** instalado en cada WordPress que quieras operar (ZIP de release de la beta).
- Acceso de administrador a esos WordPress para generar la Application Password del agente.
- `git` y, opcionalmente, `gh` (GitHub CLI).

## Instalación

```bash
# 1. Clonar
git clone git@github.com:flowtitude/kodavio-agent-kit.git
cd kodavio-agent-kit

# 2. Crear tu registro de sitios desde la plantilla (queda fuera de git)
cp registry/sites.example.json registry/sites.json

# 3. Abrir el kit con tu agente
claude        # o cursor . / codex / opencode
```

Al abrirlo, el agente lee automáticamente su puerta de entrada ([AGENTS.md](AGENTS.md) o `CLAUDE.md`) y queda operativo: conoce el protocolo, las reglas y las skills. No hay build ni dependencias que instalar.

> El kit funciona standalone. Las referencias a la doctrina interna de Soluciones Abiertas (`Playbook/`, OPS) son opcionales: si esas rutas no existen en tu máquina, el agente las omite.

## Actualizar la instalación global del agente

El kit trae lo específico de Kodavio. Para sacarle el máximo partido, completa la instalación **global** de tu agente una sola vez:

### 1. Skills oficiales de WordPress (recomendado, global)

El equipo de WordPress mantiene skills de desarrollo (bloques, temas, plugins, REST API, WP-CLI, rendimiento): [github.com/WordPress/agent-skills](https://github.com/WordPress/agent-skills). Instálalas globalmente para que estén disponibles en cualquier proyecto:

```bash
# Claude Code — pídeselo al agente:
# "Instala las skills de https://github.com/WordPress/agent-skills en ~/.claude/skills"
```

Con ellas cubres el desarrollo (código); este kit cubre la operación (sitios en vivo). Se complementan.

### 2. MCP de documentación (opcional)

Un server de docs de WordPress (p. ej. `wordpress-docs-mcp`) evita que el agente alucine funciones del core.

### 3. Verificación

Pide a tu agente: *"Lista las skills disponibles"* → deben aparecer las `wp-*` de este kit (vía `.claude/skills`) y, si las instalaste, las oficiales de WordPress.

## Onboarding: conectar tu primer sitio

**Vía recomendada — comando interactivo en el chat:**

```
/wp-onboard-site
```

(en Claude Code; en Cursor/Codex/OpenCode: *"da de alta un sitio nuevo"*). El agente te entrevista, verifica que Kodavio responde, registra el MCP en tu herramienta, rellena `registry/sites.json` con los **datos reales** del sitio (builder, theme, caveats vía `wp-get-config-summary`) y crea su memoria.

**Vía terminal (sin agente):**

```bash
./scripts/add-site.sh
```

Mismo resultado base: pregunta URL/entorno/cliente/builder, comprueba el endpoint, crea registro + memoria y deja el comando MCP listo.

Versión manual (la versión completa y a prueba de fallos es el skill [`wp-onboard-site`](skills/wp-onboard-site/SKILL.md) — puedes pedirle al agente que la ejecute y te guíe):

1. **Instala Kodavio** en el WordPress (Plugins → subir ZIP → activar).
2. En **wp-admin → Kodavio → Setup**: activa las AI abilities y genera una **Application Password** para un usuario dedicado al agente (rol mínimo necesario; *editor* si solo va a tocar contenido). Deja el PHP editing en OFF salvo que lo necesites.
3. **Registra el server MCP** en tu herramienta — plantillas exactas para Claude/Cursor/Codex/OpenCode en [docs/mcp-config-examples.md](docs/mcp-config-examples.md). Endpoint: `https://tudominio.com/wp-json/mcp/kodavio`.
4. **Reinicia el agente** y verifica: pide un `kodavio/wp-get-config-summary` del sitio.
5. **Da de alta el sitio** en `registry/sites.json` (campo a campo según la plantilla) con los datos reales del paso 4 — sobre todo `env` (production/staging/development), que es lo que activa los guardarraíles.
6. Crea su memoria: `cp -r sites/_template sites/{slug}` y rellena la ficha.
7. Checklist de seguridad del alta: backups del hosting verificados, `php_lint_available` anotado, y acordado qué puede hacer el agente sin preguntar.

**Consejo para empezar:** conecta primero un sitio de desarrollo o staging. Aprende ahí, comete los errores ahí, y pasa a producción cuando el flujo te resulte natural.

## Uso diario

Toda sesión sobre un sitio empieza por el skill **`wp-site-session`**: el agente identifica el sitio en el registry, carga su memoria y caveats, lee el handbook del servidor y aplica los guardarraíles del entorno. Después, pide lo que necesites en lenguaje natural:

| Tú dices | El sistema hace |
|---|---|
| *"¿Cómo está example.com?"* | Auditoría read-only (`wp-site-health`) → informe con riesgos y plan |
| *"Hazme la web de mi clínica"* | `wp-site-plan`: discovery → sitemap + modelo de contenido + cola de briefs → apruebas el plan → construcción página a página |
| *"Crea una página de servicios con hero, 3 features y CTA"* | `wp-page-build`: brief y copy primero → build en draft → verificación → te enseña la preview |
| *"Hazla parecida a esta captura"* (+ imagen) | `wp-reference-to-brief`: extrae estructura y jerarquía con visión → brief adaptado a TU design system → build |
| *"Escribe 5 posts sobre X para el blog"* | `wp-content-publish`: muestra 1 de ejemplo → apruebas → lote completo en draft con SEO on-page |
| *"Migra esta página de Elementor a Bricks"* | `wp-builder-convert`: plan → conversión a draft → auditoría de fidelidad → rollback garantizado |
| *"Actualiza los plugins"* | `wp-site-health`: en producción te pide confirmación update a update, con backup previo |
| *"Creo que el sitio está hackeado"* | `wp-security-triage`: contención → evidencia → limpieza → vector → hardening |

Lo que el agente **nunca** hace solo en producción: publicar, instalar/actualizar plugins, escribir PHP, borrar, operaciones masivas. Eso siempre pasa por tu confirmación explícita (matriz completa en [rules/production-guardrails.md](rules/production-guardrails.md)).

## Capacidades

### Skills del kit (cliente)

| Skill | Qué hace |
|---|---|
| [`wp-site-session`](skills/wp-site-session/SKILL.md) | Protocolo de arranque/cierre por sitio: entorno, memoria, handbook, guardarraíles |
| [`wp-onboard-site`](skills/wp-onboard-site/SKILL.md) | Comando interactivo de alta de sitio: plugin, credencial, MCP, registry con datos reales |
| [`wp-site-plan`](skills/wp-site-plan/SKILL.md) | Planificación de sitio/rediseño: discovery, sitemap, modelo de contenido, cola de briefs |
| [`wp-reference-to-brief`](skills/wp-reference-to-brief/SKILL.md) | Imagen de referencia o mockup → brief de construcción preciso (visión) |
| [`wp-page-build`](skills/wp-page-build/SKILL.md) | Páginas/secciones/templates en Bricks, Elementor o Gutenberg, con autoría previa y verificación |
| [`wp-design-patterns`](skills/wp-design-patterns/SKILL.md) | Patrones de composición: anatomía de sección, ritmo de página, catálogo (hero, features, pricing, FAQ…) |
| [`wp-bricks-fds`](skills/wp-bricks-fds/SKILL.md) | Preferencias Bricks + Flowtitude Design System: clases semánticas, tokens fluidos, elementos vetados |
| [`wp-tailwind-windpress`](skills/wp-tailwind-windpress/SKILL.md) | Tailwind v4 en WordPress vía WindPress: detección, reglas de utilities |
| [`wp-content-publish`](skills/wp-content-publish/SKILL.md) | Contenido editorial con SEO on-page y flujo draft → aprobación → publicación |
| [`wp-builder-convert`](skills/wp-builder-convert/SKILL.md) | Conversión entre builders con auditoría de fidelidad y rollback |
| [`wp-site-health`](skills/wp-site-health/SKILL.md) | Mantenimiento: updates, limpieza, salud, rendimiento |
| [`wp-security-triage`](skills/wp-security-triage/SKILL.md) | Triage de seguridad: infecciones, hardening, auditoría preventiva |

### Playbooks del servidor (Kodavio, se cargan en runtime con `kodavio/skill-get`)

`bricks-build-page` · `elementor-build-page` · `gutenberg-build-page` · `design-frameworks` · `flowtitude-design-scope` · `builder-conversion[-advanced]` · `elementor-migrate-v4` · `content-model-schema` · `dynamic-data-binding` · `acf-integration` · `jetengine-integration` · `woocommerce-operations` · `fluent-suite` · `wordpress-admin-safe`

### Subagentes (roles especializados)

| Agente | Rol |
|---|---|
| [`wp-auditor`](agents/wp-auditor.md) | Diagnóstico read-only; nunca escribe |
| [`wp-operator`](agents/wp-operator.md) | Administración WP segura: plugins, settings, usuarios |
| [`wp-bricks-operator`](agents/wp-bricks-operator.md) | Especialista Bricks (+FDS): nodos nativos, patch-first, elementos vetados |
| [`wp-elementor-operator`](agents/wp-elementor-operator.md) | Especialista Elementor: contenedores, site kit, sin addons fantasma |
| [`wp-gutenberg-operator`](agents/wp-gutenberg-operator.md) | Especialista Gutenberg: bloques core, patterns, theme.json |
| [`wp-builder-operator`](agents/wp-builder-operator.md) | Genérico de builders (fallback cuando no hay especialista) |
| [`wp-content-architect`](agents/wp-content-architect.md) | Modelo de contenido y datos dinámicos: CPTs, campos, bindings |
| [`wp-woo-operator`](agents/wp-woo-operator.md) | WooCommerce con gates de dinero (precios, pedidos, reembolsos) |
| [`wp-content-writer`](agents/wp-content-writer.md) | Copy editorial y SEO en el idioma del sitio |
| [`wp-verifier`](agents/wp-verifier.md) | Verificación adversarial post-write: read-back, salud, fidelidad, rollback |

### Flujos Kodavio cubiertos

`diagnostic_audit` · `wordpress_admin` · `design_system` · `content_model_dynamic` · `mini_plugin` · `page_creation` · `builder_migration` — enrutado completo petición → flujo → skill → gates en [workflows/WORKFLOWS.md](workflows/WORKFLOWS.md).

### Garantías operativas

- `dry_run` antes de todo write, en todos los entornos.
- Snapshot/backup antes de tocar páginas publicadas; IDs de rollback siempre en la respuesta.
- Verificación read-back tras cada escritura: "no falló" ≠ "está bien".
- Código PHP solo en sandbox recuperable o mu-plugins con lint — nunca en el tema activo ni el core ([rules/code-on-live-sites.md](rules/code-on-live-sites.md)).
- Producción trabaja en drafts; lo visible requiere aprobación humana.

## Seguridad y datos

Este repo **nunca contiene datos de sitios o clientes reales**. La separación la impone `.gitignore`:

| Versionado (el kit) | Local en tu máquina (tus datos) |
|---|---|
| Reglas, skills, agentes, workflows | `registry/sites.json` (sitios reales) |
| `registry/sites.example.json` (plantilla) | `sites/{slug}/NOTAS.md` (memoria por sitio) |
| `sites/_template/` | `state.md`, configs locales de herramientas |
| Plantillas MCP (sin credenciales) | Credenciales → access store / gestor de secretos, JAMÁS en este árbol |

Antes de hacer commit, revisa que no se cuele nada local: `git status` no debe listar `sites/` (salvo `_template`) ni `registry/sites.json`.

## Estructura del repo

```
kodavio-agent-kit/
├── AGENTS.md                  ← puerta de entrada de los agentes (fuente única)
├── CLAUDE.md                  → symlink a AGENTS.md (Claude Code)
├── .cursor/rules/             → reenvío a AGENTS.md (Cursor)
├── .claude/                   skills/ y agents/ symlinked (Claude Code)
├── registry/
│   ├── sites.example.json     ← plantilla del registro de sitios
│   └── sites.json             (local, no versionado) tus sitios reales
├── rules/                     guardarraíles por entorno · protocolo Kodavio · código en vivo
├── scripts/add-site.sh        alta de sitios por terminal (el comando es /wp-onboard-site)
├── skills/                    12 skills de orquestación, planificación y diseño (SKILL.md portables)
├── agents/                    5 subagentes especializados
├── workflows/WORKFLOWS.md     enrutado petición → flujo → skill → gates
├── sites/
│   ├── _template/NOTAS.md     ← plantilla de memoria por sitio
│   └── {slug}/                (local, no versionado) memoria de cada sitio
└── docs/
    ├── mcp-config-examples.md plantillas de conexión MCP por herramienta
    └── kodavio-vs-kit.md      doctrina: dónde vive cada capacidad nueva (plugin vs kit)
```

## Multi-agente

| Herramienta | Qué lee al entrar | MCP de sitios |
|---|---|---|
| Claude Code | `CLAUDE.md` → AGENTS.md + `.claude/skills` + `.claude/agents` | `~/.claude.json` |
| Codex | `AGENTS.md` | `~/.codex/config.toml` |
| OpenCode | `AGENTS.md` | `opencode.json` |
| Cursor | `.cursor/rules/wp-development.mdc` → AGENTS.md | `.cursor/mcp.json` |

Fuente única: `AGENTS.md`. Todo lo demás son punteros — edita siempre AGENTS.md.

## Mantener el kit al día

```bash
git pull
```

Tus datos locales (`sites.json`, `sites/*`, `state.md`) no se tocan: están fuera de git. Si una actualización cambia el esquema de `sites.example.json`, el changelog del repo lo indica y migras tu `sites.json` a mano.

Mejoras y errores del **kit** → issues/PRs en este repo. Errores del **plugin Kodavio** → canal de la beta de Flowtitude.

---

*Construido por [Soluciones Abiertas](https://solucionesabiertas.es) sobre [Kodavio](https://flowtitude.com). El agente redacta, Kodavio ejecuta, tú apruebas.*
