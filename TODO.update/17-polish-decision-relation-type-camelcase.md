# 17 — Polish: normalize `DECISION_RELATION_TYPE` camelCase mix

## Symptom

`Edoxen::Enums::DECISION_RELATION_TYPE` mixes two naming conventions:

```ruby
DECISION_RELATION_TYPE = %w[
  annexOf hasAnnex updates refines replaces considers cites
].freeze
```

`annexOf` and `hasAnnex` are camelCase; the other five are lowercase.
The same mix is in `schema/edoxen.yaml:833` and the model
`decision_relation_type.lutaml`. All three sources agree — this isn't
drift, just historical inconsistency.

Wire-naming convention in this gem is **snake_case** for all enum
values (see `MEETING_TYPE`, `AGENDA_ITEM_KIND`, etc.). The two
camelCase outliers violate the convention.

## Fix

Rename across all three sources in one commit:

- `annexOf` → `annex_of`
- `hasAnnex` → `has_annex`

Update:
- `lib/edoxen/enums.rb:54` (`DECISION_RELATION_TYPE`).
- `schema/edoxen.yaml:833` (`DecisionRelationType.enum`).
- `edoxen-model/models/decision_relation_type.lutaml` (the enum
  values).
- Any fixture using the old names. (None currently do — verify with
  `grep -rn annexOf spec/fixtures/`.)
- The lutaml↔Ruby sync spec auto-covers the rename (no test change).

## Why now

The enum has 7 values and is referenced by exactly one field
(`DecisionRelation#type`). The blast radius is small. The longer the
camelCase form lives, the more fixtures and downstream consumers bake
it in.

## Acceptance

1. No remaining `annexOf` / `hasAnnex` in `lib/`, `spec/`, or `schema/`.
2. `bundle exec rspec` passes (sync spec enforces the rename).
3. The companion PR to `edoxen-model` lands in the same release.
