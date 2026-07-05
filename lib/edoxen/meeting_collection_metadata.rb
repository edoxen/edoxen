# frozen_string_literal: true

module Edoxen
  # Top-level wrapper for many Meetings in a single YAML file. Parallel
  # to DecisionCollection. The metadata block carries display-level
  # info (title, source); per-meeting identity lives on each Meeting.
  class MeetingCollectionMetadata < Lutaml::Model::Serializable
    attribute :title, :string
    attribute :source, :string

    # v2.1 (TODO.refactor/46): per-dataset body_vocabulary. SSOT for
    # body_type → canonical_type resolution within this collection.
    attribute :body_vocabulary, BodyVocabularyEntry, collection: true

    # Resolve a body_type to its canonical_type via this collection's
    # vocabulary. Permissive — returns the body_type unchanged when no
    # matching entry exists.
    def canonical_type_for(body_type)
      return body_type if body_type.nil? || body_type.to_s.empty?
      return body_type unless body_vocabulary

      entry = body_vocabulary.find { |e| e.body_type == body_type }
      entry ? entry.canonical_type : body_type
    end
  end
end
