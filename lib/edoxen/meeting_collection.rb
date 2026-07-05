# frozen_string_literal: true

module Edoxen
  # Top-level container for many Meetings. Parallel to DecisionCollection.
  class MeetingCollection < Lutaml::Model::Serializable
    attribute :metadata, MeetingCollectionMetadata
    attribute :meetings, Meeting, collection: true

    # Find a meeting by URN. Returns nil when no meeting matches.
    def find_by_urn(urn)
      meetings&.find { |m| m.urn == urn.to_s }
    end

    # Find a meeting by StructuredIdentifier components.
    # Returns the first meeting whose any identifier matches both
    # prefix and number.
    def find_by_identifier(prefix:, number:)
      meetings&.find do |meeting|
        meeting.identifier&.any? do |id|
          id.prefix == prefix.to_s && id.number == number.to_s
        end
      end
    end
  end
end
