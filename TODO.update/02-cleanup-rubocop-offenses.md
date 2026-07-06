# 02 — Cleanup: rubocop offenses (30 → 0)

## Symptom

`bundle exec rubocop` reports 30 offenses across 128 files. v2.1/v2.2
introduced all of them; PR #20 left the count at 0.

Breakdown:
- 26 auto-correctable (`Layout/FirstArgumentIndentation`,
  `Layout/ArgumentAlignment`) in v2.1/v2.2 spec files.
- 4 manual:
  - `lib/edoxen/extension_attribute.rb:76` — `Style/Alias`:
    `alias_method :string_value, :value` should be
    `alias :string_value :value` (or just `alias string_value value`)
    in a class body.
  - `spec/support/lutaml_parser.rb:45` — `Lint/StructNewOverride`:
    `LutamlEnum = Struct.new(:name, :values, ...)` overrides
    `Struct#values`. Rename `:values` → `:entries`.
  - `spec/support/lutaml_parser.rb:67` — `Metrics/CyclomaticComplexity`
    (18/16) and `Metrics/PerceivedComplexity` (19/17) on `parse`.
    Extract the four `when` branches into small helper methods or a
    dispatch table.
- Plus a config drift:
  - `.rubocop.yml:4` — `TargetRubyVersion: 2.6` but
    `edoxen.gemspec:22` says `>= 3.0.0`. Bump to 3.0.

## Fix

1. `bundle exec rubocop -A` — auto-corrects the 26 layout nits.
2. Replace `alias_method` with `alias` in `extension_attribute.rb`.
3. Rename `LutamlEnum.values` → `.entries` (update lutaml_ruby_sync_spec
   callers).
4. Refactor `LutamlParser.parse` — extract a `dispatch(line, ctx)` helper
   or a small state-machine class. Target ≤ 16 cyclomatic / ≤ 17
   perceived.
5. Bump `.rubocop.yml` to 3.0.

## Acceptance

1. `bundle exec rubocop` reports 0 offenses.
2. `bundle exec rspec` still passes (lutaml_ruby_sync_spec continues to
   walk every lutaml class/enum).
