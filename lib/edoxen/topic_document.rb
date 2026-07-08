# frozen_string_literal: true

module Edoxen
  # TopicDocument — text-bearing document about a Topic.
  # Examples: bill text, ISO draft, report, agenda attachment.
  class TopicDocument < Lutaml::Model::Serializable
    attribute :identifier, :string
    attribute :title, LocalizedString, collection: true
    attribute :version, :string
    attribute :status, :string
    attribute :url, :string
    attribute :format, :string
    attribute :spelling, :string
    attribute :extensions, MeetingExtension, collection: true
  end
end
