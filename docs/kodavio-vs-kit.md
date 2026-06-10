# ¿Dónde vive una capacidad nueva: Kodavio (plugin) o el kit (skills)?

> Doctrina de decisión. Cuando surja "estaría bien que el agente pudiera X", esta tabla decide dónde se implementa.

## Regla de oro

**Si X requiere código ejecutándose en el WordPress → Kodavio (ability). Si X es conocimiento, criterio o proceso sobre abilities que ya existen → kit (skill).**

## Tabla de decisión

| La capacidad nueva… | Dónde | Por qué |
|---|---|---|
| Necesita leer/escribir algo que ninguna ability ni REST expone | **Kodavio** | Solo el plugin puede ejecutar PHP server-side con dry-run/backup/audit |
| Es soporte de un plugin concreto (p. ej. un page builder nuevo, un plugin de campos) | **Kodavio** (ability/adapter) | El contrato de escritura seguro debe vivir junto al dato |
| Es "cómo usar bien" abilities existentes (orden, criterio, política) | **Kit** (skill) | Iteración en minutos vía git, sin release de plugin |
| Es una preferencia/opinión del operador (widgets vetados, estilo, tono) | **Kit** | Kodavio es producto neutral; las opiniones son del operador |
| Orquesta varios sitios o combina varios MCPs | **Kit** | El plugin solo conoce SU sitio |
| Es genérica y la querría cualquier usuario de Kodavio | **Kodavio** (playbook server-side vía skill-list) | Viaja con el plugin, beneficia a todos sin el kit |
| Es un flujo con gates humanos y guardarraíles por entorno | **Kit** | Los entornos y permisos son del operador, no del sitio |

## El caso "muchos plugins" (FluentX, ACF, Woo, JetEngine, …)

Antes de pedir una ability nueva a Kodavio, agotar este orden:

1. **`mcp-adapter-discover-abilities`** — muchos plugins ya exponen abilities propias vía el adapter. Descubrir → mapear → usar. Cero código nuevo.
2. **REST API del plugin** — si el plugin tiene REST decente, una skill del kit que documente sus endpoints y políticas basta.
3. **Playbook server-side de Kodavio** (`skill-get`) — si existe (fluent-suite, woocommerce-operations, acf-integration…), la guía ya está en el plugin: el kit solo añade la política del operador encima.
4. **Ability nueva en Kodavio** — último recurso: cuando hace falta un contrato de escritura seguro que nada de lo anterior da. Entra al backlog del producto con su ciclo de QA/release.

## Costes que cada lado paga (el abogado del diablo)

**Meterlo todo en Kodavio**: el plugin engorda en sitios de clientes (superficie de riesgo, QA, soporte), cada capacidad debe ser genérica y neutral, y el ciclo de release (gate, evidencias, beta) hace que un ajuste tarde días. Un bug server-side rompe sitios ajenos.

**Meterlo todo en el kit**: las skills no pueden ejecutar nada nuevo (solo combinan lo que ya existe), el conocimiento puede desincronizarse de la versión del plugin instalada en cada sitio, y lo que vive en el kit no beneficia a usuarios de Kodavio sin kit.

El equilibrio actual: **Kodavio = manos y contrato de seguridad; kit = cabeza y criterio.** Las manos cambian despacio y con QA; la cabeza, cada día con un git pull.
