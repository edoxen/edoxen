# frozen_string_literal: true

module Edoxen
  # MeetingSeries — parent of recurring Meeting instances.
  # Crossref `proceedings-series`, IETF meeting series, Apache Board
  # meetings, etc. Carries a `Recurrence` (ISO 8601-2 §13) rule and
  # a list of member Meeting URNs.
  class MeetingSeries < Lutaml::Model::Serializable
    attribute :identifier, StructuredIdentifier, collection: true
    attribute :urn, :string
    attribute :name, :string
    attribute :description, :string
    attribute :recurrence, Recurrence
    attribute :term, :string
    attribute :contact, Contact
    attribute :hosts, HostRef, collection: true
    attribute :kind, :string
    attribute :meeting_refs, :string, collection: true
    attribute :extensions, MeetingExtension, collection: true
  end
end
