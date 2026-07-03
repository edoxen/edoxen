# frozen_string_literal: true

module Edoxen
  # VotingCounts — tally for a Voting instance.
  class VotingCounts < Lutaml::Model::Serializable
    attribute :ayes, :integer
    attribute :noes, :integer
    attribute :abstentions, :integer
    attribute :absent, :integer

    def total
      (ayes || 0) + (noes || 0) + (abstentions || 0) + (absent || 0)
    end

    def margin
      (ayes || 0) - (noes || 0)
    end

    def tied?
      ayes == noes
    end
  end
end
