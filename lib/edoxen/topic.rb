# frozen_string_literal: true

module Edoxen
  # Topic — the subject of discussion at a Meeting.
  # A Topic can have documents (text), assets (non-text), references
  # (external pointers), and is the anchor for Motions and Decisions.
  #
  # Cross-meeting threading via `resumption_of` (URN to a prior Topic
  # in a prior Meeting) — pattern from HK LegCo OData schema.
  class Topic < Lutaml::Model::Serializable
    attribute :identifier, :string
    attribute :urn, :string
    attribute :title, :string
    attribute :description, :string
    attribute :status, :string, values: Enums::TOPIC_STATUS
    attribute :resumption_of, :string
    attribute :documents, TopicDocument, collection: true
    attribute :assets, TopicAsset, collection: true
    attribute :references, Reference, collection: true
    attribute :motions, :string, collection: true
    attribute :decisions, :string, collection: true
    attribute :extensions, MeetingExtension, collection: true
  end
end
