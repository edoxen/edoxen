# frozen_string_literal: true

module Edoxen
  # TopicAsset — non-text resource about a Topic.
  # Examples: image, dataset, model, video.
  class TopicAsset < Lutaml::Model::Serializable
    attribute :identifier, :string
    attribute :title, :string
    attribute :kind, :string
    attribute :url, :string
    attribute :format, :string
    attribute :extensions, MeetingExtension, collection: true
  end
end
