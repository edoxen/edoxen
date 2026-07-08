# frozen_string_literal: true

module Edoxen
  # Motion — a procedural act that brings a Decision. "I move that..."
  # Distinct from a Decision (formal outcome) and from a TopicDocument
  # (written text). A Motion does NOT require any document.
  #
  # State machine (MotionStatus):
  #   introduced → seconded → debating → question_put → voting
  #                                                ├── carried → resulting_decision set
  #                                                ├── negatived
  #                                                ├── withdrawn
  #                                                └── lapsed
  class Motion < Lutaml::Model::Serializable
    attribute :identifier, :string
    attribute :urn, :string
    attribute :text, LocalizedString, collection: true
    attribute :mover, Person
    attribute :seconders, Person, collection: true
    attribute :status, :string, values: Enums::MOTION_STATUS
    attribute :introduced_at, :date_time
    attribute :proposed_decision, :string
    attribute :resulting_decision, :string
    # Pilot EntityRef field (v2.1, TODO.refactor/44). Parallel to
    # `resulting_decision` (String). Prefer the typed form in new code;
    # the bare String form is removed in v3.0.
    attribute :resulting_decision_ref, EntityRef
    attribute :votings, :string, collection: true
    attribute :extensions, MeetingExtension, collection: true

    def carried?
      status == "carried"
    end

    def pending?
      status && !Enums::MOTION_TERMINAL.include?(status)
    end

    # --- v2.1 derivation accessor (TODO.refactor/45) --------------------
    # Storage side: Voting.on_motion (SSOT for the Motion→Voting
    # relationship). This computed method returns the Voting instances
    # in `meeting` whose `on_motion` points at this Motion's URN.
    # The stored `votings[]` field remains on the wire for back-compat
    # through v2.x; v3.0 removes it and this becomes the only path.
    def votings_in(meeting:)
      return [] unless meeting && urn

      meeting.votings.select { |voting| voting.on_motion == urn }
    end
  end
end
