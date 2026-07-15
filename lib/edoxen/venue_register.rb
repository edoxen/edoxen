# frozen_string_literal: true

module Edoxen
  # Registry of Venues indexed by scoped URN. Mirrors ContactRegister:
  # members carry `urn: urn:edoxen:venue:{scope}:{local-id}`; the
  # collection's `scope` MUST match the scope segment in member URNs.
  # Stream loading belongs to the service layer.
  class VenueRegister < Lutaml::Model::Serializable
    attribute :scope, :string
    attribute :title, LocalizedString, collection: true
    attribute :venues, Venue, collection: true
    attribute :extensions, MeetingExtension, collection: true

    def find_by_urn(urn)
      venues&.find { |v| v.urn == urn }
    end
  end
end
