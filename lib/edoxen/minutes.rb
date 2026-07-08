# frozen_string_literal: true

module Edoxen
  # The narrative record of a Meeting — what was said, by whom, in
  # what order, with what outcome. Mirrors
  # edoxen-model/models/minutes.lutaml (P2.8 from
  # TODO.meeting-agenda/10-future-enhancements.md).
  #
  # Distinct from Agenda (the business order drafted before the
  # meeting) and from DecisionCollection (the formal decisions
  # adopted). The Minutes are the running record.
  #
  # Sections are typically keyed by agenda-item number so consumers
  # can join Minutes ↔ AgendaItem ↔ Decision by `number`/`label`.
  class Minutes < Lutaml::Model::Serializable
    attribute :identifier, StructuredIdentifier, collection: true
    attribute :urn, :string
    attribute :spelling, :string
    attribute :source_doc, :string
    attribute :source_pages, :string
    attribute :sections, MinutesSection, collection: true

    def find_section(number)
      return nil if number.nil?

      target = number.to_s
      sections&.find { |s| s.number.to_s == target }
    end
  end
end
