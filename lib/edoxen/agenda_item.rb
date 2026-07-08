# frozen_string_literal: true

module Edoxen
  # One entry on an Agenda. `label` is the visible identifier (e.g.,
  # "5.2"); `kind` discriminates numbered/unnumbered/header/opening/
  # closing/aob; `outcome` records what happened; `decision_ref`
  # optionally links to the URN of the decision this item produced.
  #
  # Topics (0..*) are the subject(s) of discussion at this agenda item.
  # AOB (Any Other Business) items have 0 topics until raised during
  # the meeting.
  class AgendaItem < Lutaml::Model::Serializable
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
