# 13 — Arch: EntityRef XOR contract (decide + enforce)

## Symptom

`EntityRef`'s class docstring says:

> Single identity: exactly one of `urn`, `identifier`, or `local_ref`
> should be set.

But `EntityRef#valid?` accepts any number ≥1:

```ruby
def valid?
  identities_set.any?
end
```

And `identities_set` returns *all* non-empty identities, not "exactly
one". The spec at `entity_ref_spec.rb:33-40` sets all three identities
simultaneously to test precedence — without flagging the violation.

Either the docstring is wrong (the contract is "at least one") or the
code is wrong (the contract is "exactly one"). Today both halves ship
and the contradiction is invisible.

## Decision

Tighten the code. Reasons:

1. The TODO 44 design (`edoxen-model/TODO.refactor/44-entityref-typed-cross-references.md`)
   explicitly says "at least one of the three required" and treats
   multiple-identity as a data error.
2. Two identities for the same entity is ambiguous — which one is
   canonical? The `#resolved_identity` precedence is a tiebreaker for
   bad data, not a feature.
3. v2.2's pilot (`Motion.resulting_decision_ref`) is the only call
   site today; no existing fixture populates multiple identities.

## Fix

```ruby
def valid?
  identities_set.size == 1
end

def multiple_identities?
  identities_set.size > 1
end
```

Add a spec example that explicitly tests a multi-identity EntityRef is
*invalid* (with a clear error path), and update the precedence spec to
acknowledge it's testing the precedence rule used for the rare
migration case (or change it to test only one identity at a time).

## Acceptance

1. `EntityRef#valid?` returns false when 0 or ≥2 identities are set.
2. New `#multiple_identities?` predicate returns true when ≥2.
3. The precedence spec no longer constructs a 3-identity ref for its
   happy path; it tests each identity in isolation.
4. `entity_ref_spec.rb` adds a clear "multiple identities is invalid"
   example.
5. The docstring's "exactly one" wording is now truthful.
