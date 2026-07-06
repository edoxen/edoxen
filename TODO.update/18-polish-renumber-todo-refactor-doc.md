# 18 — Polish: renumber my old `TODO.refactor/20-post-v2-gem-drift.md`

## Symptom

I added `edoxen-model/TODO.refactor/20-post-v2-gem-drift.md` as a
proposal. The model team later added their own `20-specs-for-model.md`
and `21-lutaml-to-ruby-sync-spec.md`. Both number series coexist now:

```
TODO.refactor/
├── 20-post-v2-gem-drift.md          ← mine (closed; for traceability)
├── 20-specs-for-model.md            ← model team
├── 21-gem-autoload-structure.md     ← model team
├── 21-lutaml-to-ruby-sync-spec.md   ← model team
├── ...
```

Numbering collisions make `ls` output ambiguous and obscure the
chronology. The master plan goes up to 49 (v2.1 status); the next free
number is 50+.

## Fix

Rename `edoxen-model/TODO.refactor/20-post-v2-gem-drift.md` →
`edoxen-model/TODO.refactor/50-post-v2-gem-drift-closed.md` and
prepend a status header:

```markdown
# 50 — Post-v2 model↔gem drift (CLOSED 2026-07-04)

Status: closed. Every item landed in `ff247a3 fix(model): close four
post-v2 model<->gem drifts`. Kept for traceability.
```

## Acceptance

1. `ls edoxen-model/TODO.refactor/` shows no duplicate numbers.
2. The new filename sorts after `49-v2.1-implementation-status.md`.
