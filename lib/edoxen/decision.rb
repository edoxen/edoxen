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
    include LocalizationHost

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
    # v2.1 (TODO.refactor/46): free-form body-specific label (e.g.
    # "Resolution", "Order", "Ruling"). Resolves to a short canonical
    # value via the parent collection's `body_vocabulary[]`.
    attribute :body_type, :string
    attribute :extensions, MeetingExtension, collection: true

    # --- v2.1 derivation accessors (TODO.refactor/45) -------------------
    # These methods compute the reverse direction of relationships whose
    # canonical storage lives elsewhere. They are additive — the stored
    # `brought_by_motions[]`, `about_topics[]`, and `made_in_component`
    # fields remain on the wire for back-compat through v2.x; v3.0
    # removes them and these methods become the only path.

    # Returns the Motions in `meeting` whose `resulting_decision` (or
    # `resulting_decision_ref`) points at this Decision's URN.
    #
    # Storage side: Motion.resultingDecision (SSOT for the relationship).
    def brought_by_motions_in(meeting:)
      return [] unless meeting && urn

      meeting.motions.select do |motion|
        motion.resulting_decision == urn ||
          motion.resulting_decision_ref&.urn == urn
      end
    end

    # Returns the MeetingComponent in `meeting` whose key matches
    # `made_in_component`.
    #
    # Storage side: Decision.madeInComponent (SSOT for the relationship).
    def component_in(meeting:)
      return nil unless meeting && made_in_component

      meeting.components&.find do |component|
        component.identifier == made_in_component ||
          component.urn == made_in_component
      end
    end
  end
end
