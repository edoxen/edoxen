# 14 — Arch: plan for migrating all String refs to EntityRef

## Symptom

v2.1 introduced `EntityRef` and shipped one pilot field
(`Motion.resulting_decision_ref`). TODO 44 listed ~15 candidate fields:

- `Motion.proposed_decision` (String)
- `Motion.resulting_decision` (String, parallel to the typed pilot)
- `Motion.votings[]` (String[])
- `Topic.motions[]`, `Topic.decisions[]` (String[])
- `Topic.resumption_of` (String)
- `Decision.brought_by_motions[]`, `Decision.about_topics[]` (String[])
- `Decision.made_in_component` (String)
- `Meeting.series_ref` (String)
- `MeetingComponent.venue_refs[]`, `agenda_ref`, `minutes_ref`,
  `attendance_refs[]` (String[] / String)
- `MeetingSeries.meeting_refs[]` (String[])
- `Voting.on_motion` (String)

All still bare `String`. The pilot will become the permanent state
unless there's a tracked plan.

This TODO captures the plan; it does **not** execute the migration.

## Plan

Two-phase:

**Phase A — additive (target v2.3):**

For each of the fields above, add a parallel typed-`EntityRef` form
(e.g. `Motion.proposed_decision_ref`) and keep the bare-String form.
Document the typed form as preferred in new code. Add an
`EntityRef#resolved_identity` helper that returns the bare-String form
so callers can switch without breakage.

**Phase B — removal (target v3.0):**

Delete the bare-String fields from Ruby + schema + lutaml. Update
fixtures. Update the MECE parity spec (TODO 10) — it becomes trivial
once there's only one form.

## Why two phases

Phase A is additive — no consumer breaks. Phase B is a breaking
release. Splitting them lets downstream consumers (OIML, TC154,
TC184/SC4) migrate at their own pace.

## Files affected (Phase A only)

For each field:
- `lib/edoxen/<entity>.rb` — add the `<name>_ref` attribute.
- `schema/edoxen.yaml` + `schema/meeting.yaml` — add the property.
- `spec/edoxen/<entity>_spec.rb` — round-trip coverage.
- `spec/edoxen/lutaml_ruby_sync_spec.rb` already enforces the lutaml
  side; the lutaml file must declare the new attribute in the same PR.

## Acceptance (for this doc)

This TODO is itself the acceptance — it documents the migration plan
and assigns phases. A separate `TODO.refactor/50-entityref-migration.md`
will track execution.

Phase A execution = future PR. Phase B = v3.0 release.
