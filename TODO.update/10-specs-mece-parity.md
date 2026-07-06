# 10 — Specs: MECE stored-vs-derived parity

## Symptom

v2.1 (TODO 45) deliberately kept both forms of every bidirectional
relationship through v2.x:

| Relationship | Stored side | Derived side (added v2.1) |
|---|---|---|
| Motion → Decision | `Motion.resulting_decision` (String), `Motion.resulting_decision_ref` (EntityRef) | `Decision#brought_by_motions_in(meeting:)` |
| Decision → Topic | `Decision.about_topics[]` (String) | `Topic#decisions_in(collection:)` |
| Motion → Voting | `Voting.on_motion` (String) | `Motion#votings_in(meeting:)` (TBD via TODO 44 full migration) |
| Decision → Component | `Decision.made_in_component` (String) | `Decision#component_in(meeting:)` |

Both sides coexist on the wire. If a fixture populates both, the
derived side and the stored side can silently disagree. The TODO 45
plan says "v3.0 removes the stored redundant fields" — but no spec
exists today to catch divergence. Removing storage without a guard =
silent breakage.

## Fix

Add `spec/edoxen/mece_parity_spec.rb`. For each relationship pair,
construct a `Meeting` (or `DecisionCollection`) where both sides are
populated consistently, then assert the derived lookup returns the
same set as the stored list. Then construct one where they disagree
and assert the derived form wins (it's the SSOT per TODO 45).

The spec also documents the policy: derived > stored for queries.

## Acceptance

1. `mece_parity_spec.rb` covers all four relationship pairs.
2. Each pair has two examples: consistent case (round-trip) and
   inconsistent case (derived wins).
3. The spec comments name the v3.0 removal target so future readers
   see why this exists.
