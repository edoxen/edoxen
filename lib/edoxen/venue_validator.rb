# frozen_string_literal: true

module Edoxen
  # VenueValidator — validates Venue instances using the `unlocodes`
  # and `iata` gems. Returns a list of errors; empty list means valid.
  #
  # For PhysicalVenue with a `unlocode` or `iata_code` field, validates
  # that the code exists in the canonical registries. Optionally
  # auto-populates city/country_code/coordinates from the registry.
  class VenueValidator
    attr_reader :venue, :errors

    def initialize(venue)
      @venue = venue
      @errors = []
    end

    def validate(auto_populate: false)
      return errors unless venue.is_a?(PhysicalVenue)

      validate_unlocode(auto_populate: auto_populate) if venue.unlocode && !venue.unlocode.to_s.empty?
      validate_iata_code if venue.iata_code && !venue.iata_code.to_s.empty?

      errors
    end

    def valid?
      validate
      errors.empty?
    end

    private

    def validate_unlocode(auto_populate:)
      entry = Edoxen::ReferenceData.find_unlocode(venue.unlocode)
      if entry.nil?
        errors << "Unknown UN/LOCODE: #{venue.unlocode}"
        return
      end

      return unless auto_populate

      venue.city ||= entry.name
      venue.country_code ||= entry.country
    end

    def validate_iata_code
      entry = Edoxen::ReferenceData.find_iata(venue.iata_code)
      return if entry

      errors << "Unknown IATA code: #{venue.iata_code}"
    end
  end
end
