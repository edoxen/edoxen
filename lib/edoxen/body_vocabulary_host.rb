# frozen_string_literal: true

module Edoxen
  # Mixed into metadata classes that carry a per-dataset
  # `body_vocabulary[]` collection (1.0, TODO.refactor/1.0-design). Provides
  # the attribute declaration and the `canonical_type_for` lookup in
  # one place so DecisionMetadata and MeetingCollectionMetadata share
  # a single implementation.
  #
  # Permissive by design: when no vocabulary entry matches a
  # body_type, the body_type string itself is returned (with no
  # warning). Strict mode is a v3.x concern.
  module BodyVocabularyHost
    def self.included(base)
      base.attribute :body_vocabulary, BodyVocabularyEntry, collection: true
    end

    # Resolve a body_type to its canonical_type via this collection's
    # vocabulary. Returns the body_type unchanged when nil/empty or
    # when no matching entry exists.
    def canonical_type_for(body_type)
      return body_type if body_type.nil? || body_type.to_s.empty?
      return body_type unless body_vocabulary

      entry = body_vocabulary.find { |e| e.body_type == body_type }
      entry ? entry.canonical_type : body_type
    end
  end
end
