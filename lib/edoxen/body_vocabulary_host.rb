# frozen_string_literal: true

module Edoxen
  # Mixed into metadata classes that carry a per-dataset
  # `body_vocabulary[]` collection (1.0, 1.0 design review). Provides
  # the attribute declaration and the `canonical_type_for` lookup in
  # one place so DecisionMetadata and MeetingCollectionMetadata share
  # a single implementation.
  #
  # Permissive by design: when no vocabulary entry matches a
  # body_type, the body_type string itself is returned (with no
  # warning). Strict mode is a v3.x concern.
  #
  # == Why the `included` hook declares the attribute
  #
  # The block-form `included` callback calls
  # `base.attribute :body_vocabulary, ...` on the includer so both
  # consumers (DecisionMetadata, MeetingCollectionMetadata) pick up
  # the attribute and the lookup method from one source. This is a
  # deliberate DRY trade-off: the alternative — declaring the
  # attribute in each metadata class — leaves the lookup method
  # without its required backing field on any class that forgets the
  # declaration. The hook makes the field and the method inseparable.
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
