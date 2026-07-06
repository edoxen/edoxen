# 07 — Sync: cross-schema SHARED_NAMES missing v2.1 + v2.2 entities

## Symptom

`spec/edoxen/schema_cross_file_sync_spec.rb` enforces byte-for-byte
equality of `$defs` re-declared across `schema/edoxen.yaml` and
`schema/meeting.yaml`. The list `SHARED_NAMES` was last updated for
v2.0 and now misses the v2.1 + v2.2 entities that are duplicated in
both files.

Missing today:

- `EntityRef` (v2.1, TODO 44)
- `BodyVocabularyEntry` (v2.1, TODO 46)
- `Contact` (v2.2)
- `ContactMethod` (v2.2)
- `ContactIdentifier` (v2.2)
- `Name` (v2.2)

Plus their two enums:

- `ContactMethodKind`
- `ContactIdentifierKind`

Today all of these happen to match byte-for-byte across the two files.
The spec just doesn't know to look at them — so a future edit that
updates one file and forgets the other will silently drift.

## Fix

Add the eight names to `SHARED_NAMES`. No code change outside the spec.

While here, add an "every shared $def declared in both files" coverage
gap spec: walk every `$defs` name in edoxen.yaml, find any that also
appears in meeting.yaml, and assert they're in `SHARED_NAMES`. This
catches the same drift next time.

## Acceptance

1. New `SHARED_NAMES` includes all eight names above.
2. The "discovery" spec passes (no surprise duplicates).
3. `bundle exec rspec spec/edoxen/schema_cross_file_sync_spec.rb`
   shows the eight new describe blocks, all green.
