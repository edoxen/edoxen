# frozen_string_literal: true

module Edoxen
  # MeetingComponent — flat sub-event of a Meeting.
  # Replaces legacy ScheduleItem.
  #
  # 1.0 (per-field localization, ISO 24229):
  #   - Removed `localizations[]` collection.
  #   - Per-field LocalizedString for title, description, time_label.
  class MeetingComponent < Lutaml::Model::Serializable
    include OfficersHost

    attribute :identifier, :string
    attribute :urn, :string
    attribute :kind, :string, values: Enums::COMPONENT_KIND
    # Identifier of the body this component belongs to. Optional;
    # usually inherited from the parent Meeting.
    attribute :body_type, :string
    attribute :title, LocalizedString, collection: true
    attribute :description, LocalizedString, collection: true
    attribute :starts_at, :date_time
    attribute :ends_at, :date_time
    attribute :time_label, LocalizedString, collection: true
    attribute :venue_refs, :string, collection: true
    attribute :officers, Officer, collection: true
    attribute :agenda_ref, :string
    attribute :minutes_ref, :string
    attribute :attendance_refs, :string, collection: true
    attribute :extensions, MeetingExtension, collection: true

    def duration_seconds
      return nil unless starts_at && ends_at

      ends_at.to_time - starts_at.to_time
    end
  end
end
