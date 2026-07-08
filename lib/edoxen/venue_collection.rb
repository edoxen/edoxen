# frozen_string_literal: true

module Edoxen
  # Registry of Venues indexed by scoped URN. Mirrors ContactCollection.
  class VenueCollection < Lutaml::Model::Serializable
    attribute :scope, :string
    attribute :title, LocalizedString, collection: true
    attribute :venues, Venue, collection: true
    attribute :extensions, MeetingExtension, collection: true

    def self.load_stream(path)
      File.open(path, "r") do |f|
        YAML.load_stream(f).map { |doc| Venue.from_hash(doc) }
      end
    end

    def find_by_urn(urn)
      venues&.find { |v| v.urn == urn }
    end
  end
end
