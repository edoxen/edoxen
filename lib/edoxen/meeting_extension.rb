# frozen_string_literal: true

module Edoxen
  # MeetingExtension — the profile mechanism (ISO 8601-2 §15).
  # Every core entity has an `extensions: MeetingExtension[0..*]` slot.
  # Adopters register their own profile namespace (e.g. "legco",
  # "us-congress", "ietf") and define `kind` values within it.
  class MeetingExtension < Lutaml::Model::Serializable
    attribute :profile, :string
    attribute :kind, :string
    attribute :ref, :string
    attribute :attributes, ExtensionAttribute, collection: true
    attribute :extensions, MeetingExtension, collection: true
  end
end
