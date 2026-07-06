# 16 — Polish: `Name#display` single-pass reject

## Symptom

`lib/edoxen/name.rb:25-26`:

```ruby
def display
  formatted || [prefix, given, additional, family, suffix]
    .reject(&:nil?).reject { |s| s.to_s.empty? }.join(" ")
end
```

Two passes over the same array. `nil.to_s` is `""` in Ruby, so
`s.to_s.empty?` already covers the `nil` case — the first `reject` is
redundant.

## Fix

```ruby
def display
  formatted || [prefix, given, additional, family, suffix]
    .reject { |s| s.to_s.empty? }.join(" ")
end
```

One pass, same behaviour.

## Acceptance

1. `name_spec.rb` (created in TODO 08) covers the `nil` and `""`
   cases for each component.
2. `person_spec.rb` still passes (it exercises `Name#display` via
   `name.display`).
3. `bundle exec rubocop` does not regress.
