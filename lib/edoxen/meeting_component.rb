# frozen_string_literal: true

module Edoxen
  # MeetingComponent — flat sub-event of a Meeting.
  # Replaces v0.x ScheduleItem. Component kinds include both
  # substantive (track, session, debate, breakout, bof, keynote) and
  # procedural (opening, closing, break, reception, registration).
  #
  # Flat by design (no nesting) per 2026-07 architectural decision.
  class MeetingComponent < Lutaml::Model::Serializable
    attribute :identifier, :string
    attribute :urn, :string
    attribute :kind, :string, values: Enums::COMPONENT_KIND
    # v2.1 (TODO.refactor/46): free-form body-specific label (e.g.
    # "Working Group Session", "Public Bill Committee Stage"). Resolves
    # to a short canonical value via the parent collection's vocabulary.
    attribute :body_type, :string
    attribute :title, :string
    attribute :description, :string
    attribute :starts_at, :date_time
    attribute :ends_at, :date_time
    # Free-form time display (e.g. "9:00–10:30") for schedules where
    # exact ISO timestamps aren't available or timezone is unknown.
    attribute :time_label, :string
    attribute :venue_refs, :string, collection: true
    attribute :officers, Officer, collection: true
    attribute :agenda_ref, :string
    attribute :minutes_ref, :string
    attribute :attendance_refs, :string, collection: true
    attribute :localizations, ComponentLocalization, collection: true
    attribute :extensions, MeetingExtension, collection: true

    def duration_seconds
      return nil unless starts_at && ends_at

      ends_at.to_time - starts_at.to_time
    end

    def officers_with_role(role)
      (officers || []).select { |o| o.role == role.to_s }
    end

    def chair
      officers_with_role("chair").first&.person
    end
  end
end
