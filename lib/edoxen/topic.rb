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

    # --- v2.1 derivation accessor (TODO.refactor/45) --------------------
    # Returns the Decisions in `collection` whose `about_topics` includes
    # this Topic's URN.
    #
    # Storage side: Decision.aboutTopics (SSOT for the relationship).
    # The stored `decisions[]` field remains on the wire for back-compat
    # through v2.x; v3.0 removes it and this becomes the only path.
    def decisions_in(collection:)
      return [] unless collection && urn

      collection.decisions.select { |decision| decision.about_topics&.include?(urn) }
    end
  end
end
