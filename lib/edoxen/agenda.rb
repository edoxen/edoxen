# frozen_string_literal: true

module Edoxen
  # The business-order document of a Meeting. Distinct from the timetable
  # (MeetingComponent) — the Agenda orders topics; components order time
  # slots. Opening/closing sessions are components, not agenda entries.
  #
  # An Agenda may be versioned independently of the Meeting: a draft
  # agenda circulates weeks before; a final agenda at meeting time;
  # an amended agenda if items are added during the meeting. The
  # `status` field captures that lifecycle.
  class Agenda < Lutaml::Model::Serializable
    attribute :identifier, StructuredIdentifier, collection: true
    attribute :status, :string, values: Enums::AGENDA_STATUS
    attribute :source_doc, :string
    attribute :items, AgendaItem, collection: true
    attribute :extensions, MeetingExtension, collection: true

    def find_item(label)
      items&.find { |item| item.label == label.to_s }
    end
  end
end
