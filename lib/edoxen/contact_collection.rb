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
  # document, for large registries that need partial updates). Stream
  # loading is a service-layer concern (file-system I/O); the model
  # owns only the (de)serialisation of one collection.
  class ContactCollection < Lutaml::Model::Serializable
    attribute :scope, :string
    attribute :title, LocalizedString, collection: true
    attribute :contacts, Contact, collection: true
    attribute :extensions, MeetingExtension, collection: true

    def find_by_urn(urn)
      contacts&.find { |c| c.urn == urn }
    end
  end
end
