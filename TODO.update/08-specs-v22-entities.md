# 08 — Specs: behavioral coverage for v2.2 Contact* + Name entities

## Symptom

v2.2 introduced four new entity classes — `Contact`, `ContactMethod`,
`ContactIdentifier`, `Name` — plus two enums (`CONTACT_METHOD_KIND`,
`CONTACT_IDENTIFIER_KIND`). They are exercised by:

- The lutaml↔Ruby sync spec (attribute shape).
- The schema↔Ruby sync spec (property shape).
- `person_spec.rb` (indirectly, via Person's contact_methods and
  identifiers).

But there is **no behavioral spec** for any of them. No round-trip
through YAML, no enum-coverage, no `Name#display` matrix, no
primary/label semantics on `ContactMethod`.

The v2.0 entities all got behavioral specs in PR #20 — the same level
of coverage should apply here.

## Fix

Add `spec/edoxen/contact_spec.rb`,
`spec/edoxen/contact_method_spec.rb`,
`spec/edoxen/contact_identifier_spec.rb`,
`spec/edoxen/name_spec.rb`.

Each covers:

- LUTAML enum coverage (every `Enums::CONTACT_METHOD_KIND` round-trips
  through `kind:`).
- All-field round-trip through YAML.
- Direct construction with real Ruby instances (no `double()`).
- Polymorphic behaviour (`ContactMethod#primary`, `Name#display`,
  `ContactIdentifier` value-keyed lookup).

The `it_behaves_like "extension host"` block is covered separately by
TODO 09.

## Acceptance

1. Four new spec files exist and pass.
2. Coverage of `Name#display`:
   - `formatted` populated → returns `formatted`.
   - `formatted` empty → builds from `[prefix, given, additional,
     family, suffix]` skipping nils / empties.
3. Coverage of `ContactMethod#primary` boolean round-trip.
4. Coverage of every value in `CONTACT_METHOD_KIND` and
   `CONTACT_IDENTIFIER_KIND` (parametrized `it`).
