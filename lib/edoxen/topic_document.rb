# frozen_string_literal: true

module Edoxen
  # TopicDocument — text-bearing document about a Topic.
  # Examples: bill text, ISO draft, report, agenda attachment.
  class TopicDocument < Lutaml::Model::Serializable
    attribute :identifier, :string
    attribute :title, :string
    attribute :version, :string
    attribute :status, :string
    attribute :url, :string
    attribute :format, :string
    attribute :language_code, :string
    attribute :extensions, MeetingExtension, collection: true
  end
end
