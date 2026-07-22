# frozen_string_literal: true

module Edoxen
  # Venue — polymorphic by discriminator, flat on the wire.
  #
  # The `kind` field discriminates between physical and virtual venues.
  # All possible fields (physical-specific and virtual-specific) live on
  # this one class as optional attributes — only the ones matching the
  # `kind` are populated.
  #
  # 1.0 (per-field localization, ISO 24229):
  #   - All translatable fields are Localized<String>[0..*].
  #   - Added: `urn` for registry storage; `ref` for reference-by-URN.
  class Venue < Lutaml::Model::Serializable
    attribute :ref, :string
    attribute :local_ref, :string
    attribute :urn, :string
    attribute :kind, :string, values: Enums::VENUE_KIND
    attribute :name, LocalizedString, collection: true
    attribute :label, LocalizedString, collection: true
    attribute :description, LocalizedString, collection: true
    attribute :capacity, :integer
    attribute :url, :string
    attribute :contact_methods, ContactMethod, collection: true

    # Physical-venue fields (populated when kind == "physical").
    attribute :unlocode, :string
    attribute :iata_code, :string
    attribute :address, LocalizedString, collection: true
    attribute :city, :string
    attribute :country_code, :string
    attribute :lat, :float
    attribute :lon, :float
    attribute :building, LocalizedString, collection: true
    attribute :floor, LocalizedString, collection: true
    attribute :room, LocalizedString, collection: true
    attribute :access_notes, LocalizedString, collection: true

    # Virtual-venue fields (populated when kind == "virtual").
    attribute :uri, :string
    attribute :features, :string, collection: true, values: Enums::VIRTUAL_FEATURE
    attribute :passcode, :string
    attribute :meeting_id, :string
    attribute :dial_in_numbers, :string, collection: true
    attribute :waiting_room, :boolean
    attribute :registration_required, :boolean

    attribute :extensions, MeetingExtension, collection: true

    def reference?
      (!ref.nil? && !ref.to_s.empty?) ||
        (!local_ref.nil? && !local_ref.to_s.empty?)
    end

    # Key used to resolve a +local_ref+ against a document-scoped
    # collection (e.g. Meeting#venues[]). Venues are keyed by urn.
    def local_lookup_key
      urn
    end

    def physical?
      kind == "physical"
    end

    def virtual?
      kind == "virtual"
    end

    def unlocode_entry
      return nil if unlocode.nil? || unlocode.to_s.empty?

      Edoxen::ReferenceData.find_unlocode(unlocode)
    end

    def iata_entry
      return nil if iata_code.nil? || iata_code.to_s.empty?

      Edoxen::ReferenceData.find_iata(iata_code)
    end

    def features_list
      return "" if features.nil? || features.empty?

      features.join(", ")
    end
  end
end
