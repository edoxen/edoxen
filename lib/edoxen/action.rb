# frozen_string_literal: true

module Edoxen
  # Verb + one effective date + per-field Localized message. Each
  # `Action` belongs to a `Decision`; the message field carries one
  # `LocalizedString` per ISO 24229 spelling.
  class Action < Lutaml::Model::Serializable
    attribute :type, :string, values: Enums::ACTION_TYPE
    attribute :date_effective, DecisionDate
    attribute :message, LocalizedString, collection: true
  end
end
