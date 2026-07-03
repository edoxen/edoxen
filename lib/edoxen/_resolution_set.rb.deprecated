# frozen_string_literal: true

require "lutaml/model"
require_relative "metadata"
require_relative "resolution"

module Edoxen
  class ResolutionSet < Lutaml::Model::Serializable
    attribute :metadata, Metadata
    attribute :resolutions, Resolution, collection: true

    key_value do
      map "metadata", to: :metadata
      map "resolutions", to: :resolutions
    end
  end
end
