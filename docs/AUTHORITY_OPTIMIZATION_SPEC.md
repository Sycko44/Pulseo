# Pulseo / Loic — Authority & Optimization Specification

Status: architecture baseline
Scope: application and sandbox control plane
Production impact: none until explicit promotion is authorized

## 1. Objective

Pulseo must distinguish three concepts that are never interchangeable:

1. capability: what a component is technically able to do;
2. authority: what it is currently permitted to do;
3. execution: the concrete action actually performed.

A capability never implies authority. Authority is evaluated before every significant action and can be narrower than the available capability.

## 2. Consent Manifest

The Consent Manifest is the root authorization contract for Pulseo / Loic.

It must be:

- explicit;
- human-readable;
- machine-evaluable;
- versioned;
- signed;
- revocable;
- scoped by resource, action, environment and duration when appropriate;
- deny-by-default outside the declared envelope.

Minimum fields:

- manifest_id;
- version;
- owner;
- issued_at;
- expires_at when temporary;
- capabilities;
- allowed_actions;
- environments;
- protected_zones;
- external_connections;
- approval_policy;
- revocation state;
- signature metadata.

Protected zones always require explicit human authorization unless a later signed manifest changes that rule. They include SSH, firewall, system accounts, secrets, public networking, privilege changes and Safety Kernel policy changes.

## 3. Human authorization model

Human validation is presented in functional language, not raw code.

For every action requiring approval, the interface should present:

- intention;
- expected result;
- affected perimeter;
- estimated blast radius;
- reversibility;
- external connections involved;
- data categories involved;
- authority requested;
- proposed duration when authority is temporary.

Suggested human choices:

- Authorize once;
- Authorize within the current manifest;
- Defer;
- Reject;
- Inspect details.

## 4. Active Task Memory

Long-term memory remains separated into:

- BRUTE: evidence and historical record;
- STRUCTURED: explicit decisions, preferences, constraints and useful facts;
- INFERRED: hypotheses and patterns, never overriding explicit user facts.

For each task, Pulseo builds a temporary Active Task Memory containing only the context needed for that task.

Pipeline:

Library -> contextual retrieval -> provenance filtering -> Active Task Memory -> OEC -> canonical execution brief.

Each important memory element must carry provenance, date, confidence and validity metadata.

## 5. Pre-action simulation and blast radius

Every significant mutable action follows:

Intention -> authority check -> dependency discovery -> simulation -> blast-radius estimate -> reversibility check -> safety gates -> execution -> verification -> receipt.

Blast radius levels:

- B1: isolated component;
- B2: service;
- B3: application;
- B4: platform;
- B5: infrastructure or externally exposed perimeter.

Increasing blast radius raises the required validation depth. B4 and B5 require explicit human authorization unless a signed rule explicitly and narrowly pre-authorizes the exact action class.

Simulation must evaluate at least:

- direct dependencies;
- parents and adjacent services;
- interface contracts;
- configuration;
- security impact;
- resource impact;
- user impact;
- rollback or reconstruction path.

## 6. Capability Broker

The Capability Broker routes subtasks to models and tools according to measured performance in real Pulseo contexts.

Its decision inputs include:

- task type;
- complexity;
- uncertainty;
- criticality;
- latency budget;
- compute budget;
- historical success rate;
- correction rate;
- safety performance;
- deterministic test performance.

Public benchmarks may seed the registry but never override observed Pulseo performance.

New models first operate in shadow mode without execution authority. Promotion requires sufficient evidence from comparable tasks.

## 7. Adaptive execution depth

Default execution depths:

### FAST
Low-impact, low-uncertainty tasks.
Single appropriate model or deterministic tool plus lightweight verification.

### STANDARD
Moderate complexity or uncertainty.
Specialized model plus deterministic tests and normal safety checks.

### CRITICAL
High impact, high uncertainty, sensitive data or broad blast radius.
Multiple independent evaluations where useful, reviewer, deterministic tests, Safety Kernel and explicit authority verification.

Depth is selected from complexity x uncertainty x impact, not from user verbosity.

## 8. Failure escalation

Repeated similar corrections are forbidden.

After repeated failure, diagnosis expands outward in this order when relevant:

component -> dependencies -> parents -> adjacent services -> interface contracts -> configuration -> architecture -> infrastructure.

Every new correction hypothesis must return through simulation and testing before execution.

## 9. Production / learning separation

Production never self-modifies.

Learning loop:

observation -> metrics -> causal diagnosis -> improvement hypothesis -> sandbox branch -> simulation -> comparative tests -> keep / reject / hybridize -> capability registry update -> lineage update.

Production receives only an explicitly promotable artifact that has passed the current gates.

## 10. Lineages

Pulseo preserves significant evolutionary branches rather than only sequential versions.

A lineage is retained when it has meaningful functional, architectural, behavioral, stability or originality value. Intermediate variants with little distinct value may be compacted while remaining reconstructible through provenance and receipts.

Hybrid experiments always create a new sandbox branch. Historical lineages are never modified in place.

## 11. Receipts

Every significant execution produces two views of the same receipt.

Human receipt:

- objective;
- previous state;
- resulting state;
- tests;
- detected regressions;
- impact;
- authority used;
- rollback/rebuild status.

Machine receipt additionally contains hashes, commit references, artifact digests, policy decisions, model/tool identities, metrics and provenance links.

## 12. Invariants

- deny by default outside explicit authority;
- capability does not imply authority;
- production does not self-modify;
- no hidden privilege expansion;
- no sensitive-zone modification without applicable explicit authorization;
- inference never overrides an explicit user fact;
- human approval is expressed primarily as intention and impact;
- significant actions are simulated when simulation is meaningful;
- every mutable significant action is traceable and verifiable;
- rollback means return to the last validated reconstructible state, not an opaque state mutation.

## 13. Implementation order

1. Define the signed Consent Manifest schema and evaluator.
2. Build Active Task Memory with provenance filtering.
3. Implement pre-action simulation, dependency graph and blast-radius scoring.
4. Implement Capability Broker registry, metrics and shadow-mode evaluation.
5. Build the human validation surface around intention, impact and result.
6. Integrate receipts and causal observability across all five components.
7. Test the complete chain in sandbox before any production promotion.

## 14. Promotion gate

This specification authorizes architecture work and sandbox implementation only.

Production promotion remains governed by the existing deployment contract and requires the relevant deployment gates to be satisfied. The current repository contract explicitly states that production deployment is not yet authorized from this repository.
