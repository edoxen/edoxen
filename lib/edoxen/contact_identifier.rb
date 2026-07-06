# frozen_string_literal: true

module Edoxen
  # One polymorphic external identifier for a Contact — ORCID, ISNI,
  # Wikidata QID, ROR, Ringgold, GitHub handle, etc. Replaces the hard-
  # coded `orcid` field. OCP: new identifier schemes are added via the
  # ContactIdentifierKind enum (or `other` + extensions).
  class ContactIdentifier < Lutaml::Model::Serializable
    attribute :kind, :string, values: Enums::CONTACT_IDENTIFIER_KIND
    attribute :value, :string
    attribute :extensions, MeetingExtension, collection: true
  end
end
