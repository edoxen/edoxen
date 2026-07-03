# frozen_string_literal: true

module Edoxen
  # Date with semantic kind. Was ResolutionDate in v0.x.
  class DecisionDate < Lutaml::Model::Serializable
    attribute :date, :date
    attribute :type, :string, values: Enums::DECISION_DATE_TYPE
  end
end
