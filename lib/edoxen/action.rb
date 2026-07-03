# frozen_string_literal: true

module Edoxen
  # Verb + one effective date + human-readable message. Used inside a
  # Localization to express the multilingual part of an action.
  class Action < Lutaml::Model::Serializable
    attribute :type, :string, values: Enums::ACTION_TYPE
    attribute :date_effective, DecisionDate
    attribute :message, :string
  end
end
