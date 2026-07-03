# frozen_string_literal: true

module Edoxen
  # Venue — polymorphic by discriminator, flat on the wire.
  #
  # The `kind` field discriminates between physical and virtual venues.
  # All possible fields (physical-specific and virtual-specific) live on
  # this one class as optional attributes — only the ones matching the
  # `kind` are populated. This avoids lutaml-model's polymorphic
  # recursion pitfalls while keeping the wire format readable.
  #
  # The PhysicalVenue and VirtualVenue subclasses exist for type-checking
  # and for carrying type-specific helpers (e.g. `#unlocode_entry`).
  # Construct them programmatically; the YAML wire format always uses
  # the flat shape via Venue.
  #
  # Replaces v0.x `Location` (physical-only) and `Meeting.virtual: Boolean`
  # (insufficient — Zoom needs URL+passcode+dial-in).
  class Venue < Lutaml::Model::Serializable
    attribute :kind, :string, values: Enums::VENUE_KIND
    attribute :name, :string
    attribute :label, :string
    attribute :description, :string
    attribute :capacity, :integer
    attribute :url, :string

    # Physical-venue fields (populated when kind == "physical").
    attribute :unlocode, :string
    attribute :iata_code, :string
    attribute :address, :string
    attribute :city, :string
    attribute :country_code, :string
    attribute :lat, :float
    attribute :lon, :float
    attribute :building, :string
    attribute :floor, :string
    attribute :room, :string
    attribute :access_notes, :string

    # Virtual-venue fields (populated when kind == "virtual").
    attribute :uri, :string
    attribute :features, :string, collection: true, values: Enums::VIRTUAL_FEATURE
    attribute :passcode, :string
    attribute :meeting_id, :string
    attribute :dial_in_numbers, :string, collection: true
    attribute :waiting_room, :boolean
    attribute :registration_required, :boolean

    attribute :extensions, MeetingExtension, collection: true

    def physical?
      kind == "physical"
    end

    def virtual?
      kind == "virtual"
    end

    # Resolve the UN/LOCODE entry via the canonical `unlocodes` gem.
    # Returns an Unlocodes::Entry or nil when the code is empty / unknown.
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
