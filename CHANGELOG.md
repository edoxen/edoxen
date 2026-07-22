# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

* `Edoxen::EntityResolver` no longer duck-types its scoped-collection
  members with `respond_to?(:urn)`. Each resolvable entity
  (`Contact`, `Venue`, `Body`) now exposes `#local_lookup_key`, which
  returns the canonical local identifier for that type (`urn` for
  Contact/Venue, `code` for Body). The resolver calls the polymorphic
  method directly — adding a new resolvable entity type means adding
  the method on the class, not branching in the resolver.

## [0.8.3] — 2026-07-18

### Fixed

* `Meeting#decisions` is `StructuredIdentifier[]` (reference by
  prefix+number), aligning the Ruby model with the JSON schema and
  every consumer dataset; the attribute had drifted to `Decision`
  during the BS 0 minutes work (mirrors edoxen-model#26).
* `Edoxen::EntityResolver` document-scoped tier no longer raises
  `NoMethodError` for `Body` — bodies have no `urn`, they are keyed
  by `code` (same semantics as `BodyRegister#find_by_urn`).

## [0.8.2] — 2026-07-17

### Added

* **Three-tier entity resolution** for Contact, Venue, and Body:
  inline (full data, no reference), document-scoped (`local_ref` →
  matching member in the container's scoped collection, e.g.
  `Meeting#contacts[]`, `Meeting#bodies[]`), and global register
  (`ref` → member of a top-level register document).
* `Contact#local_ref` alongside `ref`; `Contact#reference?` true when
  either is set.
* New `Body` entity (`code`, localized `name`, `kind`, `parent_ref`,
  `ref`, `local_ref`) and `BodyRegister` top-level document.
  `Meeting#committee` and `Meeting#committee_group` changed from
  `String` to `Body`.
* `Edoxen::EntityResolver` — pure resolution service walking
  inline → scoped → register.
* `AgendaItem#urn` + `Edoxen::UrnFor` — hierarchical agenda-item
  URNs (`{meetingUrn}:agenda:{label}`), computable when absent in
  source data.

### Changed

* `ContactCollection` renamed to `ContactRegister`;
  `VenueCollection` renamed to `VenueRegister` (a register is
  authoritative and persistent, a collection is just a grouping).

## [0.8.1] — 2026-07-14

First implementation release of **Edoxen Model 1.0**. The Ruby gem
mirrors the canonical LutaML information model in
[edoxen/edoxen-model](https://github.com/edoxen/edoxen-model): a
generic meeting, agenda, motion, voting, and decision model with
VCARD-style contacts, scoped URN registries, and per-field
localization per ISO 24229.

### Identity & Contact (VCARD-style, OCP)

* `Contact` — VCARD-like abstract contact (person, organisation,
  department, or role).
* `Person` — inherits from `Contact` for individual humans.
* `Name` — structured N + FN components (formatted, family, given,
  additional, prefix, suffix).
* `ContactMethod` — polymorphic communication channel (phone, mobile,
  fax, email, url, mail, pager, message, other).
* `ContactIdentifier` — polymorphic external ID (orcid, isni,
  wikidata, ror, ringgold, github, other).
* `Officer` — role-binding (NOT an entity): binds a Contact to a
  Meeting or MeetingComponent with a structural role (chair,
  secretary, treasurer, etc.).
* `HostRef` — typed reference to a hosting organization.

### Localization (per-field, ISO 24229)

Every translatable field is `Localized<String/Name>[0..*]` — one
entry per ISO 24229 `spelling` code. There is no separate
`Localization[]` collection; each field carries its own language tags.

* `LocalizedString` — `{ spelling, value: String, extensions }`.
* `LocalizedName` — `{ spelling, value: Name, extensions }`.
* `spelling` accepts ISO 24229 spelling-system codes
  (`{lang}-{script}[-{country}][-{extension}]`, e.g. `zho-Hans`) AND
  conversion-system codes (`{authority}:{source}:{target}:{identifying}`,
  e.g. `acadsin:zho-Hani:Latn:2002`).
* Always verbose — single-language data uses the same
  `[{ spelling, value }]` shape as multi-language data.
* Ruby helpers: `Contact#name_in(spelling)`, `Meeting#title_in(spelling)`,
  `Contact#localized_value(field, spelling)`.

### Scoped URN registries

URN format: `urn:edoxen:{entity}:{scope}:{local-id}`. Helper:
`Edoxen::Urn.parse`, `Edoxen::Urn.format`, `Edoxen::Urn.valid?`.

* `ContactCollection` — registry of Contacts indexed by scoped URN.
  `ContactCollection.load_stream(path)` for YAML Stream files.
* `VenueCollection` — registry of Venues.
* `Contact` and `Venue` gain `urn` (registry identity) and `ref`
  (when used as a URN reference; if set, other fields are ignored).

Any entity-typed field accepts either **inline data** (full object) or
**a URN reference** (`{ ref: urn:edoxen:contact:... }`).

### Meeting/Agenda side

`Meeting`, `MeetingCollection`, `MeetingSeries`, `MeetingComponent`,
`Agenda` + `AgendaItem`, `Minutes` + `MinutesSection`, `Attendance`,
`VoteRecord`, `Venue` (polymorphic physical/virtual, flat wire shape),
`Deadline`, `MeetingRelation`, `Recurrence` (structured ISO 8601-2 §13).

### Decision side

`Decision`, `DecisionCollection` + `DecisionMetadata`, `DecisionDate`,
`Action`, `Consideration`, `Approval` (each with per-field Localized
message), `DecisionRelation`, `SourceUrl`.

### Procedural

`Motion` (state machine), `Voting` + `VotingCounts`, `Topic` +
`TopicDocument` + `TopicAsset` (cross-meeting threading via
`resumptionOf`).

### Profile mechanism (ISO 8601-2 §15)

`MeetingExtension` + `ExtensionAttribute` — how adopters express
body-specific structured data. Core stays generic.
`BodyVocabularyEntry` — per-dataset vocabulary mapping (body_type →
canonical_type). `EntityRef` — typed cross-reference between entities.

### Schemas

* `schema/edoxen.yaml` — DecisionCollection schema (decision side).
* `schema/meeting.yaml` — Meeting / MeetingCollection / MeetingSeries
  schema (meeting side).
* All enums mirror `Edoxen::Enums` constants; sync specs assert
  character-for-character equality.
* Cross-file sync spec ensures shared `$defs` are byte-for-byte equal
  across the two schema files.

### Spec coverage

* 6 lutaml ↔ Ruby / schema sync specs (316 + 314 + 60 + 630 + 30
  examples, all green).
* 1327 unit / fixture specs green.
* `Edoxen::SchemaValidator`, `Edoxen::LinkChecker`, `Edoxen::Cli` all
  exercised.

### BS 0:2006 meeting-minutes integration

* `Statement` — one remark by one or more members on a topic or a
  minutes section. `kind: StatementKind` discriminates
  `statement` / `comment` / `standpoint` (BS 0:2006 §7.6).
* `Declaration` — formal declaration (conflict of interest, IPR).
  `kind: DeclarationKind` discriminates. IPR declarations carry
  typed `EntityRef` slots for `ipr_subject_ref` and `ipr_target_ref`.
* `DateTimeRange` — sub-day precision parallel to `DateRange`.
* `Meeting#scheduled_date_range` (renamed from `date_range`) +
  `Meeting#occurred_date_range: DateTimeRange` +
  `Meeting#declarations: Declaration[0..*]`.
* `Topic#statements[]` (standing) + `Topic#declarations[]` (standing).
* `MinutesSection#statements[]` (per-meeting) +
  `MinutesSection#topic_ref` (URN back-link to Topic).
* Every new translatable field is per-field Localized (ISO 24229) —
  no scalar `String` text fields anywhere in the new surface.

### References

* [Edoxen Model 1.0](https://github.com/edoxen/edoxen-model) —
  canonical LutaML information model.
* ISO 24229 — spelling/conversion system codes.
* VCARD (RFC 6350) — N + FN name structure.
* ISO 8601-2 (2026) §13 for recurrence, §15 for profile mechanism.
* iCalendar (RFC 5545/7986/5546/9253) — referenced, not duplicated.
