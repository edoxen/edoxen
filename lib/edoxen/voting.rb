# frozen_string_literal: true

module Edoxen
  # Voting — state machine for a single vote on a Motion.
  # Multiple votings can occur on the same Motion (e.g., unclear voice
  # vote → chair calls a formal division → second Voting instance).
  #
  # State machine (VotingStatus):
  #   called → in_progress → decided | withdrawn | deferred
  class Voting < Lutaml::Model::Serializable
    attribute :identifier, :string
    attribute :urn, :string
    attribute :on_motion, :string
    attribute :status, :string, values: Enums::VOTING_STATUS
    attribute :method, :string, values: Enums::VOTING_METHOD
    attribute :called_by, Person
    attribute :called_at, :datetime
    attribute :result_declared_at, :datetime
    attribute :result, :string, values: Enums::VOTING_OUTCOME
    attribute :counts, VotingCounts
    attribute :casting_vote, VoteRecord
    attribute :vote_records, VoteRecord, collection: true
    attribute :extensions, MeetingExtension, collection: true

    def decided?
      status == "decided"
    end

    def in_progress?
      status == "in_progress"
    end

    def passed?
      decided? && result == "passed"
    end

    def negatived?
      decided? && result == "negatived"
    end

    def tied?
      decided? && result == "tied"
    end
  end
end
