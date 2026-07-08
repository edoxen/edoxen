# frozen_string_literal: true

module Edoxen
  # Top-level container for a published decision collection: metadata
  # plus the list of decisions. Was ResolutionCollection in legacy.
  class DecisionCollection < Lutaml::Model::Serializable
    attribute :metadata, DecisionMetadata
    attribute :decisions, Decision, collection: true
  end
end
