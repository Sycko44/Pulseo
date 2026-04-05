# Pulseo Execution Pack v1.2

Ce pack complete la specification v1.2 et sert de base de demarrage immediate pour une equipe de developpeurs junior.

## Contenu
- `api/openapi.yaml` - contrat API REST v1 MVP
- `api/events/*.schema.json` - schemas d'evenements asynchrones
- `infra/docker-compose.yml` - stack locale reproductible
- `infra/.env.example` - variables d'environnement de reference
- `docs/monorepo-structure.md` - arborescence cible du repo
- `docs/mvp-contract.md` - perimetre MVP verrouille
- `docs/data-consent-matrix.md` - matrice donnees / finalites / consentements
- `docs/definition-of-done.md` - Definition of Done transverse
- `ux/baseline-ux-reference.md` - reference UX minimale obligatoire
- `runbooks/*.md` - procedures incidents et operations courantes
- `backlog/p0-p05-p1.md` - backlog initial ordonne
- `backlog/go-no-go-checklist.md` - checklist de readiness
- `scripts/bootstrap.sh` - initialisation locale
- `scripts/create-monorepo-tree.sh` - structure de demarrage

## Ordre recommande
1. Lire `docs/mvp-contract.md`
2. Lire `docs/monorepo-structure.md`
3. Configurer `infra/.env.example`
4. Lancer `infra/docker-compose.yml`
5. Executer `scripts/bootstrap.sh`
6. Implementer d'abord le backlog `P0`, puis `P0.5`
7. Utiliser `runbooks/` pour toute manipulation d'exploitation

## Regles de travail
- Aucune fonctionnalite hors MVP avant validation du noyau runtime/auth/home/health/story/studio minimal.
- Aucun moteur implicite sans consentement explicite.
- Toute recommandation sensible doit etre explicable.
- Toute promotion de regle sensible doit etre journalisee et reversible.
- L'application mobile reste le shell baseline. L'edge, le spatial et la simulation viennent en extension.

## Livrables attendus a la fin du sprint 1
- Auth fonctionnelle
- Consentements granulaire minimum
- Runtime local avec healthcheck
- Accueil baseline
- Module sante simple
- Story engine minimal
- Backoffice minimal
- Audit log minimum
