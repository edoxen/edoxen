# frozen_string_literal: true

module Edoxen
  # A single Meeting (event) — produces Decisions via Motions and Votings.
  # Carries identity, time, polymorphic venues, officers, agenda, components,
  # attendance, minutes, and URN links to one or more DecisionCollection
  # documents.
  #
  # 1.0 (per-field localization, ISO 24229):
  #   - Removed `localizations[]` collection.
  #   - Added per-field LocalizedString for title, general_area,
  #     practical_info, note.
  class Meeting < Lutaml::Model::Serializable
    include OfficersHost

    attribute :identifier, StructuredIdentifier, collection: true
    attribute :urn, :string
    attribute :ordinal, :integer
    attribute :series_ref, :string
    attribute :type, :string, values: Enums::MEETING_TYPE
    attribute :status, :string, values: Enums::MEETING_STATUS
    attribute :visibility, :string, values: Enums::VISIBILITY
    attribute :body_type, :string

    attribute :title, LocalizedString, collection: true
    attribute :scheduled_date_range, DateRange
    attribute :occurred_date_range, DateTimeRange
    attribute :recurrence, Recurrence

    attribute :venues, Venue, collection: true
    attribute :general_area, LocalizedString, collection: true
    attribute :practical_info, LocalizedString, collection: true
    attribute :city, :string
    attribute :country_code, :string

    attribute :committee, Body
    attribute :committee_group, Body

    attribute :officers, Officer, collection: true
    attribute :hosts, HostRef, collection: true

    attribute :source_urls, SourceUrl, collection: true
    attribute :landing_url, :string
    attribute :registration_url, :string
    attribute :note, LocalizedString, collection: true
    attribute :contact, Contact
    attribute :contacts, Contact, collection: true
    attribute :bodies, Body, collection: true

    attribute :agenda, Agenda
    attribute :components, MeetingComponent, collection: true
    attribute :deadlines, Deadline, collection: true

    attribute :attendance, Attendance, collection: true
    attribute :minutes, Minutes, collection: true
    attribute :declarations, Declaration, collection: true

    # Outcomes (canonical location on Meeting)
    attribute :decisions, Decision, collection: true
    attribute :motions, Motion, collection: true
    attribute :votings, Voting, collection: true

    attribute :relations, MeetingRelation, collection: true
    attribute :extensions, MeetingExtension, collection: true

    def find_agenda_item(label)
      agenda&.find_item(label)
    end

    def city_entry
      return nil if city.nil? || city.to_s.empty?

      Edoxen::ReferenceData.find_unlocode(city)
    end
  end
end
