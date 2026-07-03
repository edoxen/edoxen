# frozen_string_literal: true

module Edoxen
  # Directed relation between two decisions, identified by their
  # StructuredIdentifier (prefix + number).
  class DecisionRelation < Lutaml::Model::Serializable
    attribute :source, StructuredIdentifier
    attribute :destination, StructuredIdentifier
    attribute :type, :string, values: Enums::DECISION_RELATION_TYPE
  end
end
