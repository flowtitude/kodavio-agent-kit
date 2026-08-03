# Propuesta — Kit público de Kodavio

> Qué se abre al público y qué se queda. Objetivo: repo público, instalable en un paso, licenciado y documentado, con lo SA-interno fuera. El "gate" de negocio NO es ocultar skills — es que las valiosas llaman a `kodavio/*` (necesitas el plugin). Modelo = `bricks-skills` (gratis, MIT, público, para vender Bricks).
> Estado: propuesta para OK de AJ.

## Curación

### Skills (16 → 14 públicas)

| Skill | Público | Por qué |
|---|---|---|
| wp-site-session | ✅ | Protocolo base, genérico |
| wp-onboard-site | ✅ | Conecta un sitio a Kodavio (es funnel: onboarda el plugin) |
| wp-site-plan | ✅ | Planificación, método |
| wp-page-build | ✅ | Skill insignia (construcción) |
| wp-reference-to-brief | ✅ | Imagen → brief |
| wp-design-patterns | ✅ | Composición, método |
| wp-bricks-fds | ✅ | Bricks + FDS (FDS es gancho de Flowtitude) |
| wp-tailwind-windpress | ✅ | Genérico (Tailwind/WindPress) |
| wp-content-publish | ✅ | Contenido editorial |
| wp-copywriting | ✅ | Copy comercial |
| wp-marketing | ✅ | Plan de marketing |
| wp-patterns-author | ✅ | Extender el catálogo de Kodavio (funnel) |
| wp-builder-convert | ✅ | Muestra el moat; choca el muro (necesita `kodavio/*`) |
| wp-site-health | ✅ | Mantenimiento |
| **wp-security-triage** | ❌ | Depende del MCP `wp-malware-cleanup` + protocolo de brechas del Playbook (SA) |
| **wp-security-cleanup** | ❌ | Orquesta MCP interno de SA + Playbook. No portable sin SA |

→ **14 públicas, 2 fuera.** Opción futura: versión genérica "security-basics" sin las dependencias SA.

### Agentes (10 → todos públicos)
Roles genéricos (auditor, operator, builder/bricks/elementor/gutenberg-operator, content-architect, woo-operator, content-writer, verifier). Prompts portables, sin nada SA. **Van todos.**

### Reglas (6 → todas públicas)
`production-guardrails`, `execution-profile`, `kodavio-protocol`, `code-on-live-sites`, `ability-source-agnostic`, `skill-phases`. **Son el moat de disciplina** — precisamente lo que hay que enseñar. Van todas.

## Fuera del público (SA-interno)
- `.komandesk/` y su doc de bootstrap interno de SA — ya fuera del repo (commit `4fd8b86`).
- Secciones SA de `AGENTS.md` ("Doctrina superior (capa SA)", "Komandesk Agent Kit") → degradar a "SA-only, ignóralo si no eres SA" (ya están marcadas opcionales) o quitarlas.
- Datos locales (`registry/sites.json`, `sites/{slug}`) — ya gitignored, no están en el repo.
- Las 2 skills de seguridad (arriba).

## Empaquetado (mecánico, ~horas)
- **README** con 3 canales de instalación: (a) `git clone` en `~/.claude/skills/`, (b) `.claude-plugin/marketplace.json` para `claude plugin marketplace add`, (c) zip → claude.ai Skills.
- **LICENSE** — recomendado **MIT** (como bricks-skills).
- Nota grande y clara: **"Necesitas el plugin Kodavio en tu WordPress"** + link a flowtitude.com/kodavio. Sin el plugin, las skills chocan el muro.
- `registry/sites.example.json` ya existe (plantilla sin datos).
- Barrido final: cero credenciales, cero rutas SA, cero nombres de cliente.

## Decisiones que quedan (para AJ)
1. **Licencia**: MIT recomendado.
2. **Repo público**: ¿mismo `flowtitude/kodavio-agent-kit` hecho público, o repo nuevo `kodavio-skills` limpio?
3. **Las 2 de seguridad**: ¿fuera del todo, o versión genérica más adelante?
4. **Timing de publicación**: el trabajo se puede hacer ya; publicar cuando la campaña esté lista (septiembre) — construir ahora, publicar cuando toque.
