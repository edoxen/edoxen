# frozen_string_literal: true

module Edoxen
  # ExtensionAttribute — a key-value pair within a MeetingExtension.
  # Used by adopters to carry profile-specific data without modifying
  # the core schema (ISO 8601-2 §15 profile mechanism).
  class ExtensionAttribute < Lutaml::Model::Serializable
    attribute :key, :string
    attribute :value, :string
  end
end
