# 03 — Cleanup: anti-pattern `respond_to?` in EntityRef

## Symptom

`lib/edoxen/entity_ref.rb:61` uses `value.respond_to?(:to_s)` to gate
the `.to_s.empty?` call. Per the project's hard rules (CLAUDE.md +
global instructions):

> Never use `respond_to?` for type checking — design so the type
> hierarchy makes the check unnecessary, or use `is_a?`.

In this case the values come from a fixed set (`[urn, identifier,
local_ref]`): `urn` and `local_ref` are `:string` attributes;
`identifier` is a `StructuredIdentifier`. All three respond to `to_s`
via Ruby's `Object#to_s`. The check is unnecessary *and* masks intent.

## Fix

Replace:

```ruby
def identities_set
  [urn, identifier, local_ref].reject do |value|
    value.nil? || (value.respond_to?(:to_s) && value.to_s.empty?)
  end
end
```

with:

```ruby
def identities_set
  [urn, identifier, local_ref].reject do |value|
    case value
    when nil then true
    when String then value.empty?
    else false
    end
  end
end
```

The `case` makes the per-type behaviour explicit: Strings must be
non-empty; StructuredIdentifier is "present" by virtue of being
instantiated; nil is rejected.

## Acceptance

1. `entity_ref_spec.rb` still passes.
2. No remaining `respond_to?` calls in `lib/edoxen/`.
3. `bundle exec rubocop` does not regress.
