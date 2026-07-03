# frozen_string_literal: true

module Edoxen
  # ComponentLocalization — per-language content for a MeetingComponent.
  class ComponentLocalization < Lutaml::Model::Serializable
    attribute :language_code, :string
    attribute :script, :string
    attribute :title, :string
    attribute :description, :string
  end
end
