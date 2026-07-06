# 05 — DRY: extract `LocalizationHost` module

## Symptom

`Decision#in_language` (`lib/edoxen/decision.rb:34-43`) and
`Meeting#in_language` (`lib/edoxen/meeting.rb:61-70`) are byte-for-byte
identical, modulo the `localizations` collection type. Both pick a
localization by `language_code`, fall back to the first if asked.

The shape:

```ruby
def in_language(code, fallback: false)
  match = localizations&.find { |loc| loc.language_code == code.to_s }
  return match if match

  fallback ? localizations&.first : nil
end

def primary_localization
  in_language("eng", fallback: true)
end
```

## Fix

Extract to a module that relies on the including class having a
`localizations` attribute (any typed collection).

```ruby
# lib/edoxen/localization_host.rb
module Edoxen
  module LocalizationHost
    def in_language(code, fallback: false)
      match = localizations&.find { |loc| loc.language_code == code.to_s }
      return match if match

      fallback ? localizations&.first : nil
    end

    def primary_localization
      in_language("eng", fallback: true)
    end
  end
end
```

`include` on `Decision` and `Meeting`.

Register autoload in `lib/edoxen.rb`.

## Notes

- `MeetingLocalization` (the meeting-side per-language class) and
  `ComponentLocalization` (component-side) carry `language_code` too
  but don't have their own `localizations[]` collection, so they don't
  include the module.
- `ScheduleItem` and `Location` are gone (deleted in PR #20), so the
  only two consumers are `Decision` and `Meeting`.

## Acceptance

1. `decision_lookup_spec.rb` and `meeting_lookup_spec.rb` still pass.
2. No remaining `def in_language` or `def primary_localization` in
   `lib/edoxen/` outside the new module.
