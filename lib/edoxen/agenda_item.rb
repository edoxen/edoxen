# frozen_string_literal: true

module Edoxen
  # One entry on an Agenda. `label` is the visible identifier (e.g.,
  # "5.2"); `kind` discriminates numbered/unnumbered/header/opening/
  # closing/aob; `outcome` records what happened; `decision_ref`
  # optionally links to the URN of the decision this item produced.
  #
  # `urn` is the first-class URN of this item, derived from the parent
  # meeting URN and the label (e.g. "urn:oiml:ciml:meeting:ciml-60:agenda:6.2").
  # It is optional in source data — when absent it can be computed on
  # the fly via {Edoxen::UrnFor.agenda_item}.
  #
  # Topics (0..*) are the subject(s) of discussion at this agenda item.
  # AOB (Any Other Business) items have 0 topics until raised during
  # the meeting.
  class AgendaItem < Lutaml::Model::Serializable
    attribute :urn, :string
    attribute :label, :string
    attribute :kind, :string, values: Enums::AGENDA_ITEM_KIND
    attribute :title, LocalizedString, collection: true
    attribute :description, LocalizedString, collection: true
    attribute :references, Reference, collection: true
    attribute :outcome, :string, values: Enums::AGENDA_ITEM_OUTCOME
    attribute :decision_ref, :string
    attribute :topics, Topic, collection: true
    attribute :components, :string, collection: true
    attribute :extensions, MeetingExtension, collection: true
  end
end
