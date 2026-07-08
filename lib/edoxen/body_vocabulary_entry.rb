# frozen_string_literal: true

module Edoxen
  # BodyVocabularyEntry — one entry in a per-dataset body_vocabulary
  # list (1.0, TODO.refactor/1.0-design).
  #
  # Maps a free-form `body_type` (e.g. "CIML Meeting", "Plenary") to a
  # short canonical value (e.g. "plenary"). Bodies declare their
  # vocabulary on the collection metadata; consumers look up the
  # canonical_type via the parent collection's vocabulary.
  #
  # SSOT: the body_vocabulary list on collection metadata is the single
  # source of truth for body_type → canonical_type resolution within
  # that dataset.
  #
  # Permissive: when no vocabulary entry matches a body_type, the gem
  # returns the body_type string itself (with a warning at debug
  # level). Strict mode is a v3.x concern.
  class BodyVocabularyEntry < Lutaml::Model::Serializable
    attribute :body_type, :string
    attribute :canonical_type, :string
    attribute :definition, :string
  end
end
