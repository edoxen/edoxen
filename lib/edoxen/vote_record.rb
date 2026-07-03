# frozen_string_literal: true

module Edoxen
  # A single vote on a Decision, recorded against the Voting instance
  # that captured it. `voting_ref` links to the Voting URN; `decision_ref`
  # links to the Decision URN (often derivable from the Voting's motion,
  # but explicit for clarity).
  #
  # `role` is open for adopter-defined values: teller (parliamentary
  # division counter), proxy_holder, observer, etc.
  class VoteRecord < Lutaml::Model::Serializable
    attribute :decision_ref, :string
    attribute :voting_ref, :string
    attribute :person, Person
    attribute :affiliation, :string
    attribute :vote, :string, values: Enums::VOTE_TYPE
    attribute :role, :string
    attribute :notes, :string
    attribute :extensions, MeetingExtension, collection: true

    key_value do
      map "decision_ref", to: :decision_ref
      map "voting_ref", to: :voting_ref
      map "person", to: :person
      map "affiliation", to: :affiliation
      map "vote", to: :vote
      map "role", to: :role
      map "notes", to: :notes
      map "extensions", to: :extensions
    end

    def affirmative?
      vote == "affirmative"
    end

    def teller?
      role == "teller"
    end
  end
end
