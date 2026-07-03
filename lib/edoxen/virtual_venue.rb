# frozen_string_literal: true

module Edoxen
  # VirtualVenue — type marker for a Venue with kind == "virtual".
  #
  # The wire format is flat on Venue (all fields live there). This
  # subclass exists for type-checking and to host virtual-only helpers
  # so callers can ask `venue.is_a?(VirtualVenue)` and validators
  # can dispatch by type.
  class VirtualVenue < Venue
    def initialize(attributes = {})
      super(attributes.merge(kind: "virtual"))
    end
  end
end
