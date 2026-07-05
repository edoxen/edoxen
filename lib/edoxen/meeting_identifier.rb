# frozen_string_literal: true

module Edoxen
  # Identifier of a meeting (venue + date). Singular — the meeting a
  # particular Decision belongs to.
  class MeetingIdentifier < Lutaml::Model::Serializable
    attribute :venue, :string
    attribute :date, :date
  end
end
