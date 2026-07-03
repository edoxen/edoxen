# frozen_string_literal: true

module Edoxen
  # PhysicalVenue — a physical place where a Meeting happens.
  # Carries UN/LOCODE and IATA codes for canonical identification,
  # plus full address and geo-coordinates. Validated against the
  # `unlocodes` and `iata` gems by Edoxen::VenueValidator.
  class PhysicalVenue < Venue
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

    # Resolve the UN/LOCODE entry via the canonical `unlocodes` gem.
    # Returns an Unlocodes::Entry (with #name, #country, #coordinates,
    # etc.) or nil when the code is empty / unknown.
    def unlocode_entry
      return nil if unlocode.nil? || unlocode.to_s.empty?

      Edoxen::ReferenceData.find_unlocode(unlocode)
    end

    # Resolve the IATA code via the canonical `iata` gem.
    # Returns an Iata::Entry or nil.
    def iata_entry
      return nil if iata_code.nil? || iata_code.to_s.empty?

      Edoxen::ReferenceData.find_iata(iata_code)
    end
  end
end
