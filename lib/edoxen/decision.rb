# frozen_string_literal: true

module Edoxen
  # A formal Decision — the base type for any outcome adopted by a Meeting.
  # Was `Resolution` in v0.x; renamed in v2.0 because the same formal concept
  # has many names across bodies (resolution, order, ruling, determination,
  # finding, opinion). `Resolution` is one `kind` value, not a class name.
  #
  # v3.0 (per-field localization, ISO 24229):
  #   - Removed `localizations[]` collection.
  #   - Per-field LocalizedString for title, subject, message, considering.
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
    attribute :body_type, :string
    attribute :title, LocalizedString, collection: true
    attribute :subject, LocalizedString, collection: true
    attribute :message, LocalizedString, collection: true
    attribute :considering, LocalizedString, collection: true
    attribute :considerations, Consideration, collection: true
    attribute :approvals, Approval, collection: true
    attribute :actions, Action, collection: true
    attribute :extensions, MeetingExtension, collection: true

    def title_in(spelling, fallback: true)
      entry = title&.find { |l| l.spelling == spelling.to_s }
      entry ||= title&.first if fallback
      entry&.value
    end

    # --- v2.1 derivation accessors (TODO.refactor/45) -------------------

    def brought_by_motions_in(meeting:)
      return [] unless meeting && urn

      meeting.motions.select do |motion|
        motion.resulting_decision == urn ||
          motion.resulting_decision_ref&.urn == urn
      end
    end

    def component_in(meeting:)
      return nil unless meeting && made_in_component

      meeting.components&.find do |component|
        component.identifier == made_in_component ||
          component.urn == made_in_component
      end
    end
  end
end
