# 09 — Specs: apply `extension host` shared examples to v2.2 entities

## Symptom

The shared example `it_behaves_like "extension host"` (in
`spec/support/extension_host_shared_examples.rb`) is currently included
on every v2.0 entity that hosts `extensions: MeetingExtension[0..*]`.

The four new v2.2 entities — `Contact`, `ContactMethod`,
`ContactIdentifier`, `Name` — all declare `extensions` and are not yet
covered. The shared example catches:

- YAML round-trip of `extensions[]` with a typed ExtensionAttribute
  list.
- The v2.1 wire shape (`type:` discriminator, `intValue`,
  `dateTimeValue`, etc.).
- Back-compat with the v2.0 bare `value:` form.

## Fix

Add `it_behaves_like "extension host", factory: {}` to:

- `spec/edoxen/contact_spec.rb` (created in TODO 08).
- `spec/edoxen/contact_method_spec.rb` (created in TODO 08).
- `spec/edoxen/contact_identifier_spec.rb` (created in TODO 08).
- `spec/edoxen/name_spec.rb` (created in TODO 08).

(Person already includes it after PR #20.)

## Acceptance

1. The four new entity specs include the shared example.
2. `bundle exec rspec` count increases by 4 × 6 = ~24 examples.
3. All green.
