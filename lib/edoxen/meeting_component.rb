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
    attribute :title, :string
    attribute :description, :string
    attribute :starts_at, :datetime
    attribute :ends_at, :datetime
    attribute :venue_refs, :string, collection: true
    attribute :chair, Person
    attribute :agenda_ref, :string
    attribute :minutes_ref, :string
    attribute :attendance_refs, :string, collection: true
    attribute :localizations, ComponentLocalization, collection: true
    attribute :extensions, MeetingExtension, collection: true

    def duration_seconds
      return nil unless starts_at && ends_at

      ends_at.to_time - starts_at.to_time
    end
  end
end
