# frozen_string_literal: true

module Edoxen
  # A formal Decision — the base type for any outcome adopted by a Meeting.
  # Was `Resolution` in v0.x; renamed in v2.0 because the same formal concept
  # has many names across bodies (resolution, order, ruling, determination,
  # finding, opinion). `Resolution` is one `kind` value, not a class name.
  #
  # Language-agnostic admin fields live here; every translatable field is
  # wrapped inside `localizations[]` (one entry per available language; at
  # least one is required by the schema).
  class Decision < Lutaml::Model::Serializable
    attribute :identifier, StructuredIdentifier, collection: true
    attribute :kind, :string, values: Enums::DECISION_KIND
    attribute :status, :string, values: Enums::DECISION_STATUS
    attribute :doi, :string
    attribute :urn, :string
    attribute :agenda_item, :string
    attribute :dates, DecisionDate, collection: true
    attribute :categories, :string, collection: true
    attribute :meeting, MeetingIdentifier
    attribute :relations, DecisionRelation, collection: true
    attribute :urls, Url, collection: true
    attribute :brought_by_motions, :string, collection: true
    attribute :about_topics, :string, collection: true
    attribute :made_in_component, :string
    attribute :localizations, Localization, collection: true
    attribute :extensions, MeetingExtension, collection: true

    def in_language(code, fallback: false)
      match = localizations&.find { |loc| loc.language_code == code.to_s }
      return match if match

      fallback ? localizations&.first : nil
    end

    def primary_localization
      in_language("eng", fallback: true)
    end
  end
end
