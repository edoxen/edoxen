# 11 — Specs: canonical-enum ≤ 5 architectural invariant

## Symptom

v2.1 (TODO 46) introduced three short canonical enums:
`DECISION_KIND_CANONICAL` (5), `MEETING_TYPE_CANONICAL` (4),
`COMPONENT_KIND_CANONICAL` (5). The "≤ 5 canonical values" rule is a
hard architectural cap — bodies extend via `body_type: String` +
`body_vocabulary[]`, not by growing the enum.

`body_vocabulary_spec.rb:7-26` asserts the **current** sizes but not
the cap. A future PR that adds a sixth canonical value silently breaks
the design.

## Fix

Add one spec to `body_vocabulary_spec.rb`:

```ruby
it "every *_CANONICAL enum is within the v2.1 cap of 5" do
  %i[DECISION_KIND_CANONICAL MEETING_TYPE_CANONICAL COMPONENT_KIND_CANONICAL].each do |c|
    expect(Edoxen::Enums.const_get(c).size).to be <= 5,
      "#{c} exceeds the v2.1 canonical cap of 5; extend via body_vocabulary instead"
  end
end
```

## Acceptance

1. The new example exists.
2. It would fail if someone added a sixth value to any of the three
   constants.
3. `bundle exec rspec` count +1.
