# frozen_string_literal: true

module Edoxen
  # A single Meeting (event) — produces Decisions via Motions and Votings.
  # Carries identity, time, polymorphic venues, officers, agenda, components,
  # attendance, minutes, and URN links to one or more DecisionCollection
  # documents.
  #
  # Meetings and DecisionCollections are kept as separate documents and
  # joined by URN because they have different lifetimes: agendas exist
  # weeks before a meeting; decisions only after adoption.
  class Meeting < Lutaml::Model::Serializable
    attribute :identifier, StructuredIdentifier, collection: true
    attribute :urn, :string
    attribute :ordinal, :integer
    attribute :series_ref, :string
    attribute :type, :string, values: Enums::MEETING_TYPE
    attribute :status, :string, values: Enums::MEETING_STATUS
    attribute :visibility, :string, values: Enums::VISIBILITY
    # v2.1 (TODO.refactor/46): free-form body-specific label (e.g.
    # "CIML Meeting", "Plenary", "Board Meeting"). Resolves to a short
    # canonical value via the parent collection's `body_vocabulary[]`.
    attribute :body_type, :string

    attribute :date_range, DateRange
    attribute :recurrence, Recurrence

    attribute :venues, Venue, collection: true
    attribute :general_area, :string
    attribute :city, :string
    attribute :country_code, :string

    attribute :committee, :string
    attribute :committee_group, :string

    attribute :officers, Officer, collection: true
    attribute :hosts, HostRef, collection: true

    attribute :source_urls, SourceUrl, collection: true
    attribute :landing_url, :string
    attribute :registration_url, :string

    attribute :agenda, Agenda
    attribute :components, MeetingComponent, collection: true
    attribute :deadlines, Deadline, collection: true

    attribute :attendance, Attendance, collection: true
    attribute :minutes, Minutes, collection: true

    # Outcomes (canonical location on Meeting)
    attribute :decisions, Decision, collection: true
    attribute :motions, Motion, collection: true
    attribute :votings, Voting, collection: true

    attribute :localizations, MeetingLocalization, collection: true
    attribute :relations, MeetingRelation, collection: true
    attribute :extensions, MeetingExtension, collection: true

    def in_language(code, fallback: false)
      match = localizations&.find { |loc| loc.language_code == code.to_s }
      return match if match

      fallback ? localizations&.first : nil
    end

    def primary_localization
      in_language("eng", fallback: true)
    end

    def find_agenda_item(label)
      agenda&.find_item(label)
    end

    # Resolve the meeting's UN/LOCODE via the canonical `unlocode` gem.
    def city_entry
      return nil if city.nil? || city.to_s.empty?

      Edoxen::ReferenceData.find_unlocode(city)
    end

    # Officers filtered by role. Returns empty array when no officers
    # or no matching role.
    def officers_with_role(role)
      officers&.select { |o| o.role == role.to_s } || []
    end

    def chair
      officers_with_role("chair").first&.person
    end

    def secretary
      officers_with_role("secretary").first&.person
    end

    # All physical venues (polymorphic Venue filter).
    def physical_venues
      venues_by_kind("physical")
    end

    def virtual_venues
      venues_by_kind("virtual")
    end

    def hybrid?
      !physical_venues.empty? && !virtual_venues.empty?
    end

    def virtual_only?
      !virtual_venues.empty? && physical_venues.empty?
    end

    def physical_only?
      !physical_venues.empty? && virtual_venues.empty?
    end

    private

    def venues_by_kind(kind)
      (venues || []).select { |v| v.kind == kind }
    end
  end
end
