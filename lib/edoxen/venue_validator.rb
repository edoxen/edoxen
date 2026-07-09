# frozen_string_literal: true

module Edoxen
  # VenueValidator — validates Venue instances using the `unlocodes`
  # and `iata` gems. Returns a list of errors; empty list means valid.
  #
  # For a Venue with `kind: "physical"`, validates that any populated
  # `unlocode` and `iata_code` exist in the canonical registries.
  #
  # `valid?` and `validate` are pure queries — they do not mutate the
  # venue. Callers who want city/country_code back-filled from the
  # UN/LOCODE registry use `populate_from_registry!`, a separate,
  # explicitly-mutating method.
  class VenueValidator
    attr_reader :venue, :errors

    def initialize(venue)
      @venue = venue
      @errors = []
    end

    # Pure query. Populates `errors` and returns it; does not modify
    # the venue.
    def validate
      errors.clear
      validate_physical if venue.physical?
      errors
    end

    # Pure boolean wrapper around `validate`.
    def valid?
      validate
      errors.empty?
    end

    # Mutator: back-fill `venue.city` and `venue.country_code` from the
    # UN/LOCODE entry. Raises `KeyError` when the unlocode is unknown
    # or unset, so callers do not silently leave the venue untouched.
    #
    # Returns the venue (so callers can chain).
    def populate_from_registry!
      raise KeyError, "populate_from_registry! requires kind: physical" unless venue.physical?
      raise KeyError, "populate_from_registry! requires unlocode" if venue.unlocode.nil? || venue.unlocode.to_s.empty?

      entry = Edoxen::ReferenceData.find_unlocode(venue.unlocode)
      raise KeyError, "Unknown UN/LOCODE: #{venue.unlocode}" if entry.nil?

      venue.city ||= entry.name
      venue.country_code ||= entry.country
      venue
    end

    private

    def validate_physical
      validate_unlocode if venue.unlocode && !venue.unlocode.to_s.empty?
      validate_iata_code if venue.iata_code && !venue.iata_code.to_s.empty?
    end

    def validate_unlocode
      entry = Edoxen::ReferenceData.find_unlocode(venue.unlocode)
      return if entry

      errors << "Unknown UN/LOCODE: #{venue.unlocode}"
    end

    def validate_iata_code
      entry = Edoxen::ReferenceData.find_iata(venue.iata_code)
      return if entry

      errors << "Unknown IATA code: #{venue.iata_code}"
    end
  end
end
