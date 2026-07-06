# frozen_string_literal: true

module Edoxen
  # Top-level wrapper for many Meetings in a single YAML file. Parallel
  # to DecisionCollection. The metadata block carries display-level
  # info (title, source); per-meeting identity lives on each Meeting.
  class MeetingCollectionMetadata < Lutaml::Model::Serializable
    include BodyVocabularyHost

    attribute :title, :string
    attribute :source, :string
  end
end
