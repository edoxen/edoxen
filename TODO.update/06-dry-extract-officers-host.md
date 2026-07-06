# 06 — DRY: extract `OfficersHost` module

## Symptom

`Meeting#officers_with_role` (`lib/edoxen/meeting.rb:85-87`) and
`MeetingComponent#officers_with_role`
(`lib/edoxen/meeting_component.rb:39-41`) are the same logic, modulo
`officers&.select` vs `(officers || []).select`. Both classes also
define a `chair` accessor that calls `officers_with_role("chair").first&.person`.

The shape (after normalising the `nil` guard):

```ruby
def officers_with_role(role)
  (officers || []).select { |o| o.role == role.to_s }
end

def chair
  officers_with_role("chair").first&.person
end
```

## Fix

Extract to a module that requires the including class to have an
`officers` attribute.

```ruby
# lib/edoxen/officers_host.rb
module Edoxen
  module OfficersHost
    def officers_with_role(role)
      (officers || []).select { |o| o.role == role.to_s }
end

    def chair
      officers_with_role("chair").first&.person
    end
  end
end
```

`include` on `Meeting` and `MeetingComponent`.

While here, normalise `Meeting#officers_with_role` to the
`(officers || [])` form (it currently uses `officers&.select ... || []`
— semantically identical but inconsistent).

Register autoload in `lib/edoxen.rb`.

## Notes

- Only `Meeting` and `MeetingComponent` carry officers. No other class
  needs this module.
- Do not extract `secretary` (only on `Meeting`) — it's role-specific
  to one class.

## Acceptance

1. `meeting_spec.rb` and `meeting_component_spec.rb` still pass.
2. No remaining `def officers_with_role` outside the new module.
3. `bundle exec rubocop` does not regress.
