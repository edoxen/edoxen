# 01 — Cleanup: dead identity `key_value` blocks

## Symptom

`EntityRef` and `BodyVocabularyEntry` declare a `key_value do … end`
block whose body is purely `map "attr", to: :attr` for every attribute.
Per CLAUDE.md:

> lutaml-model auto-emits an identity map for each attribute when no
> `key_value` block is present. Add a `key_value do … end` block with
> `map "wire_name", to: :attr` only when the wire name differs from the
> attribute name.

These blocks are dead code — they restate the default. Same
anti-pattern that was removed from `VoteRecord` and `Attendance` in
PR #20.

## Files

- `lib/edoxen/entity_ref.rb:26-33` — 7-line identity block.
- `lib/edoxen/body_vocabulary_entry.rb:24-28` — 3-line identity block.

`ExtensionAttribute` (`extension_attribute.rb:47-56`) is **not** dead —
it remaps `intValue` → `:integer_value` etc. Leave alone.

## Fix

Delete the two `key_value do … end` blocks. The lutaml↔Ruby sync spec
already covers attribute names; the wire shape is unchanged because
the auto-emitted identity map matches.

## Acceptance

1. `bundle exec rspec` still 1122 / 0.
2. `bundle exec rubocop` does not regress.
3. YAML round-trip on a fixture with `extensions: [{ profile: legco,
   attributes: [...] }]` still parses.
