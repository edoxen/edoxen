# frozen_string_literal: true

module Edoxen
  # PhysicalVenue — type marker for a Venue with kind == "physical".
  #
  # The wire format is flat on Venue (all fields live there). This
  # subclass exists for type-checking and to host physical-only helpers
  # so callers can ask `venue.is_a?(PhysicalVenue)` and validators
  # can dispatch by type.
  class PhysicalVenue < Venue
    def initialize(attributes = {})
      super(attributes.merge(kind: "physical"))
    end
  end
end
