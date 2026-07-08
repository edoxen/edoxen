# frozen_string_literal: true

module Edoxen
  # Registry of Contacts indexed by scoped URN. Members carry
  # `urn: urn:edoxen:contact:{scope}:{local-id}`; the collection's
  # `scope` MUST match the scope segment in member URNs.
  #
  # Other documents (Meeting, MeetingComponent, HostRef, etc.) reference
  # contacts via `ref: urn:edoxen:contact:{scope}:{local-id}` and
  # resolve against the matching ContactCollection.
  #
  # Storage: single YAML file (typical) or YAML Stream (one Contact per
  # document, for large registries that need partial updates).
  class ContactCollection < Lutaml::Model::Serializable
    attribute :scope, :string
    attribute :title, LocalizedString, collection: true
    attribute :contacts, Contact, collection: true
    attribute :extensions, MeetingExtension, collection: true

    # Load a YAML Stream file (one Contact per document). Returns an
    # Array of Contact instances. Glossarist-style batch registry.
    def self.load_stream(path)
      File.open(path, "r") do |f|
        YAML.load_stream(f).map { |doc| Contact.from_hash(doc) }
      end
    end

    def find_by_urn(urn)
      contacts&.find { |c| c.urn == urn }
    end
  end
end
