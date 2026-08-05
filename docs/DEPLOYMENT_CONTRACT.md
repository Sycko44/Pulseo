# Pulseo deployment contract

## Roles

- GitHub stores reviewed source code, manifests, tests and deployment declarations.
- Vault stores secrets and issues short-lived credentials.
- Sandbox proves build, startup, health and rollback before production.
- VPS executes an approved immutable release.

## Required flow

1. Import the stable VPS application into a review branch.
2. Remove secrets, runtime data, caches, logs and local model files.
3. Reproduce the service with one canonical Docker Compose definition.
4. Run tests and a local health check.
5. Authenticate the deployer to Vault using a bounded identity.
6. Render runtime secrets into memory or a restricted temporary file.
7. Deploy to sandbox and record the release digest.
8. Prove health and rollback.
9. Promote the exact tested digest to production.
10. Produce a deployment receipt containing commit, digest, checks and result.

## Safety gates

Production deployment remains disabled until all of these are true:

- The repository contains the actual FastAPI service running on the VPS.
- No secret or Vault token is committed.
- Vault authentication and policy are verified.
- The service starts from the canonical Compose file without hidden manual steps.
- Health checks pass in sandbox.
- Rollback to the prior release is tested.
- Nginx and systemd changes are declared and reviewed.

## Vault rules

- Never place root tokens, static Vault tokens or private keys in GitHub.
- Use the narrowest policy required by the Pulseo service.
- Prefer short-lived credentials and renewable leases.
- Keep application secrets separate from deployment credentials.
- Record secret paths and policy names, never secret values.
- Revoke temporary credentials after deployment.

## Current status

- The obsolete Node/Next automatic deployment has been locked.
- The current FastAPI VPS source has not yet been imported into this repository.
- Vault installation, seal state, authentication method and policies still require live VPS verification.
- No production deployment is authorized from this repository yet.
