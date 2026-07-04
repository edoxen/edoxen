# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
