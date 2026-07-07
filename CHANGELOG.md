# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.3] — 2026-07-07

Patch release. Fixes the `ExtensionAttribute` schema to use the
camelCase wire names that match the lutaml-model mapping in
`lib/edoxen/extension_attribute.rb` (`map "intValue", to:
:integer_value`, etc.).

Before this fix, any YAML fixture using the documented v2.1 typed
ExtensionAttribute wire form (`intValue`, `floatValue`,
`booleanValue`, `dateValue`, `dateTimeValue`) failed the schema's
`additionalProperties: false` check. The schema declared snake_case
property names that didn't match the camelCase wire names.

Mirror change in `edoxen-model/schema/{decision-collection,meeting}.yaml`.

The schema-model-sync spec gets a small `WIRE_NAME_RENAMES` override
table for ExtensionAttribute — its attribute-to-property name mapping
is intentionally lossy (Ruby snake_case ↔ wire camelCase) and that's
the documented design.

## [2.1.2] — 2026-07-07

Patch release. Adds `MeetingSeries` as a valid top-level document in
`schema/meeting.yaml` so downstream consumers can ship a
committee-level MeetingSeries fixture as the single source of truth
for committee metadata (name, description, chair as `contact`,
secretariat as `hosts[]`, social-media URLs as `extensions[]`).
Previously MeetingSeries was only reachable as a `$ref` inside other
documents.

Backwards-compatible: existing Meeting and MeetingCollection root
documents still validate unchanged.

Mirror change in `edoxen-model/schema/meeting.yaml`.

## [2.1.1] — 2026-07-06

Patch release. Bundles the v2.2 OCP refactor (Contact family), the
post-v2.2 audit cleanup, and the gem↔model canonical-schema sync spec.


### Added

- **Contact family** (v2.2 OCP refactor): `Contact`, `Name`,
  `ContactMethod`, `ContactIdentifier` classes plus
  `CONTACT_METHOD_KIND` and `CONTACT_IDENTIFIER_KIND` enums. `Person`
  now inherits from `Contact`; the hard-coded `email` / `phone` /
  `orcid` fields are replaced by typed `contact_methods[]` and
  `identifiers[]` collections. New channel/identifier kinds land via
  the enum (or `other` + extensions) — no model change (OCP).
- **BodyVocabularyHost / LocalizationHost / OfficersHost modules.**
  DRY the `body_vocabulary` + `canonical_type_for` lookup, the
  `in_language` + `primary_localization` accessors, and the
  `officers_with_role` + `chair` accessors across the classes that
  share them.
- **Behavioral specs for Contact, ContactMethod, ContactIdentifier,
  Name** — each with the typed ExtensionAttribute round-trip via
  `it_behaves_like "extension host"`.
- **MECE parity spec** (`spec/edoxen/mece_parity_spec.rb`) covering
  all four v2.1 bidirectional pairs (Motion↔Decision, Decision↔
  Component, Decision↔Topic, Motion↔Voting). Guards the v3.0
  stored-side removal.
- **Canonical-enum ≤5 architectural invariant** in
  `body_vocabulary_spec.rb`.
- **Body-vocabulary metadata YAML round-trip** on both
  `DecisionMetadata` and `MeetingCollectionMetadata`.
- **Cross-schema sync spec** (`spec/edoxen/schema_cross_file_sync_spec.rb`):
  23 shared `$defs` between `schema/edoxen.yaml` and `schema/meeting.yaml`
  enforced byte-equal. Discovery spec catches future omissions from
  `SHARED_NAMES`.
- **Gem↔model canonical schema sync spec**
  (`spec/edoxen/schema_model_canonical_sync_spec.rb`, 126 examples):
  every `$defs` entry in the gem's mirror schemas is enforced
  byte-equal to the model's canonical `schema/decision-collection.yaml`
  and `schema/meeting.yaml`. Skips when the model repo isn't checked
  out.

### Changed

- **EntityRef XOR contract enforced.** `EntityRef#valid?` now returns
  true only when exactly one of `urn` / `identifier` / `local_ref` is
  set (was: any number ≥1). New `#multiple_identities?` predicate
  flags ambiguous data. The wire contract documented in
  `edoxen-model/TODO.refactor/44-entityref-typed-cross-references.md`
  is now truthful.
- **`Motion#pending?` derived from `Edoxen::Enums::MOTION_TERMINAL`.**
  New constant partitions `MOTION_STATUS` cleanly; a coverage spec
  asserts the union equals `MOTION_STATUS` (MECE invariant).
- **CLI refactored to a Profile-based dispatch.** `validate` /
  `normalize` / `validate-meetings` / `normalize-meetings` collapse to
  one-line delegations; option parsing and batch scaffolding share a
  single runner.
- **VenueValidator dispatches on `kind`, not `is_a?`.** Wire-parsed
  Venues (always flat `Venue`, never `PhysicalVenue`) now validate
  correctly.
- **`LutamlParser.parse` refactored into five small state-handler
  methods.** Cyclomatic and perceived complexity now within rubocop
  limits. `LutamlEnum.values` renamed to `.items` to avoid
  `Struct#values` / `#entries` override.
- **`Name#display` single-pass reject** (was: two passes).
- **`annexOf` / `hasAnnex` → `annex_of` / `has_annex`** across gem
  Ruby, gem schema, model lutaml, and model schema. The camelCase
  outliers were the only wire-form inconsistency in any enum.

### Removed

- **Dead identity `key_value` blocks** on `EntityRef` and
  `BodyVocabularyEntry` (lutaml-model auto-emits identity maps).
- **`respond_to?(:to_s)`** in `EntityRef#identities_set` — replaced
  with a `case` over `nil` / `String` / else.
- **Duplicate `canonical_type_for`**, `in_language` /
  `primary_localization`, and `officers_with_role` / `chair`
  implementations — moved to the new shared modules.

### Infrastructure

- **`.rubocop.yml` `TargetRubyVersion` 2.6 → 3.1.** `NewCops: enable`.
  `Metrics/ModuleLength` excluded for the spec-side LutaML parser;
  `Metrics/BlockLength` excluded for spec files generally.
- **`edoxen.gemspec` `required_ruby_version` 3.0 → 3.1.** Ruby 3.0
  reached EOL March 2024. Migrated to `YAML.safe_load_file`.
- **`TODO.*/` added to `.gitignore`** — local planning notes never
  committed.
- **`entry.country` → `entry.country_iso2`** in the `edoxen iata` CLI
  (was calling a method that didn't exist on `Iata::Entry`).

### Test results

1339 examples, 0 failures. 0 rubocop offenses.

## [2.1.0] — 2026-07-05

Edoxen v2.1 is a backwards-compatible minor release that tightens the
profile mechanism and adds the LutaML↔Ruby regression net.


### Added

- **LutaML ↔ Ruby sync spec** (`spec/edoxen/lutaml_ruby_sync_spec.rb`):
  walks every `class` block in `edoxen-model/models/*.lutaml` and
  asserts the matching `Edoxen::*` Ruby class declares the same
  attribute names + collection flags. Closes the root-cause gap from
  the v2.0 drift audit.
- **LutaML enum ↔ Ruby sync** (in the same spec): walks every `enum`
  block and asserts value-for-value equality with the matching
  `Edoxen::Enums::*` constant.
- **Typed ExtensionAttribute variants**: `integer_value`, `float_value`,
  `boolean_value`, `date_value`, `date_time_value` plus a `type`
  discriminator. New `#typed_value` reader picks the right variant.
  String values still use the bare `value:` wire name (v2.0 back-compat).

### Changed

- **MeetingExtension field semantics documented.** `kind` is the
  in-profile discriminator; `ref` is the URN of an external profile
  document. Field behavior is unchanged; the docs are now explicit.
- **LutaML model files** synced to match the gem after the drift audit
  closed four real drifts (Voting.method, Agenda three drifts, missing
  url.lutaml, vestigial subject_body.lutaml).

### Removed

- **Recursive `extensions[]` slot on MeetingExtension.** YAGNI — no
  documented use case. Profiles needing nesting use dotted keys
  (`vote.count`, `vote.method`) in `attributes[]`.

### Compatibility

v2.0 fixtures continue to parse and round-trip unchanged. The v2.0
bare `value: String` wire shape on ExtensionAttribute still works;
the gem routes it into the string variant with `type` defaulted to
`"string"`.

## [2.0.0] — 2026-07-04

Edoxen v2.0 broadens the model from a standards-body-specific Resolution
model to a **generic meeting, agenda, motion, voting, and decision
model** with profile extensions for domain-specific concepts.

### Post-launch drift closures (2026-07-04)

Per the post-v2 model↔gem drift audit (`edoxen-model/TODO.refactor/20-post-v2-gem-drift.md`):

- Added `extensions: MeetingExtension[0..*]` to `DecisionMetadata` —
  closes the inverse drift where the gem was missing what every other
  v2 collection-level entity already had.


### Breaking changes

- Renamed `Resolution` → `Decision`. `Resolution` is now a `DecisionKind` value.
- Renamed `ResolutionCollection` → `DecisionCollection`.
- Renamed `ResolutionMetadata` → `DecisionMetadata`.
- Renamed `ResolutionDate` → `DecisionDate`; `ResolutionDateType` → `DecisionDateType`.
- Renamed `ResolutionRelation` → `DecisionRelation`; `ResolutionRelationType` → `DecisionRelationType`.
- Renamed `ResolutionType` → `DecisionKind` (with expanded values: resolution, order, ruling, determination, recommendation, statement, finding, opinion, other).
- Renamed `Voting.method` → `Voting.voting_method` (avoids Ruby Object#method conflict).
- Removed `Meeting.virtual: Boolean`. Replaced with polymorphic `Meeting.venues: Venue[]`.
- Removed `Meeting.chair` and `Meeting.secretary` direct shortcuts. Replaced with `Meeting.officers: Officer[]` (role discriminates). `Meeting#chair` and `Meeting#secretary` remain as lookup helpers.
- Removed `Meeting.schedule: ScheduleItem[]`. Replaced with `Meeting.components: MeetingComponent[]` (flat).
- Removed `Meeting.host` (singular String). Use `Meeting.hosts: HostRef[]`.
- Removed `Meeting.year` (derivable from `date_range.start`).
- Renamed `Meeting.resolution_refs` → `Meeting.decisions` (inline Decision objects).
- Removed `AgendaItem.resolution_ref`. Use `AgendaItem.decision_ref`.
- Removed `Agenda.opening_session` / `Agenda.closing_session` (ScheduleItem references). These are now `MeetingComponent`s.
- Removed `VoteRecord.resolution_ref`. Use `VoteRecord.decision_ref` + `VoteRecord.voting_ref`.
- lutaml-model attribute type `:datetime` is now `:date_time` (lutaml-model 0.8+ naming).

### Added

- `Decision` base type with `kind`, `status`, and procedural fields
  (`brought_by_motions`, `about_topics`, `made_in_component`).
- `Motion` entity — procedural act with state machine:
  `introduced → seconded → debating → question_put → voting → carried/negatived/withdrawn/lapsed`.
- `Voting` entity — vote state machine:
  `called → in_progress → decided | withdrawn | deferred`; `voting_method`,
  `counts`, `casting_vote`, `vote_records`.
- `VotingCounts` — ayes / noes / abstentions / absent; derived `#total`,
  `#margin`, `#tied?`.
- `Topic`, `TopicDocument`, `TopicAsset` — the subject of discussion.
  Cross-meeting threading via `resumption_of`.
- `MeetingSeries` — parent of recurring meetings.
- `MeetingComponent` — flat sub-events (replaces ScheduleItem). Kinds:
  track, session, debate, breakout, bof, keynote, opening, closing,
  break, reception, etc.
- `ComponentLocalization` — per-language content for a component.
- `Officer` + `OfficerRole` (replaces chair/secretary shortcuts).
- `MeetingExtension` + `ExtensionAttribute` — profile mechanism
  (ISO 8601-2 §15). Every core entity has an `extensions[]` slot.
- `Recurrence` + `RecurrenceByDay` — structured ISO 8601-2 §13
  (queryable, not opaque RRULE).
- `Venue` polymorphic (kind: physical | virtual). Single flat class on
  the wire; `kind` discriminates which fields are expected.
- `PhysicalVenue`, `VirtualVenue` — Ruby subclasses for type-checking
  and helper methods.
- `VenueValidator` — validates Venue instances against the `unlocodes`
  and `iata` gems; optionally auto-populates `city` / `country_code`
  from the UN/LOCODE registry.
- Extended `Attendance` with `role` (AttendanceRole) and `response`
  (AttendanceResponse, from iCalendar PARTSTAT, plain English).
- Extended `AgendaItem` with `topics[]` and `components[]`.
- Extended `Person` with `kind` and `orcid`.
- Extended `Meeting` with `urn`, `ordinal`, `series_ref`, `visibility`,
  `recurrence`, `landing_url`, `registration_url`.
- New enums: `VenueKind`, `VirtualFeature`, `Visibility`,
  `AttendanceRole`, `AttendanceResponse`, `ComponentKind`,
  `DecisionKind`, `DecisionStatus`, `MotionStatus`, `VotingStatus`,
  `VotingMethod`, `VotingOutcome`, `TopicStatus`, `OfficerRole`,
  `RecurrenceFreq`.
- CLI: `edoxen iata CODE` command (parallels `edoxen unlocode`).
- RBS signatures (`sig/edoxen.rbs`) for every public class and method.

### Integration

- `unlocodes` gem for UN/LOCODE validation (runtime dependency).
- `iata` gem for IATA code validation (runtime dependency).

### References

- iCalendar (RFC 5545/7986/5546/9253) — referenced, not duplicated.
- ISO 8601-2 (2026) §13 for recurrence, §15 for profile mechanism.

### Migration

See the [migration guide](https://github.com/edoxen/edoxen.github.io/blob/main/docs/migration-v2.md)
for the full v0.x → v2.0 transformation.

## [1.0.0] — 2026-06-30

Initial public release. Standards-body-focused Resolution model with
Meeting + Agenda + Minutes + Attendance + VoteRecord side.

## [0.1.0] — 2025-XX-XX

Initial development release.
