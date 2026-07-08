# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.8.0] — Unreleased

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

### References

* [Edoxen Model 1.0](https://github.com/edoxen/edoxen-model) —
  canonical LutaML information model.
* ISO 24229 — spelling/conversion system codes.
* VCARD (RFC 6350) — N + FN name structure.
* ISO 8601-2 (2026) §13 for recurrence, §15 for profile mechanism.
* iCalendar (RFC 5545/7986/5546/9253) — referenced, not duplicated.
