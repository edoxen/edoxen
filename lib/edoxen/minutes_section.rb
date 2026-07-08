# frozen_string_literal: true

module Edoxen
  # One section of a Meeting's minutes — typically tied to an agenda
  # item by its `number` field. Carries the narrative as Markdown
  # (the format the GLM-OCR pipeline emits) plus optional page range
  # for provenance back to the source PDF.
  #
  # Localization lives on the parent Minutes document, not on each
  # section — Minutes has a per-document language_code; the section
  # lookup is `Minutes#find_section(number)`. Earlier copies of this
  # class inherited `in_language`/`primary_localization` from
  # ScheduleItem/Meeting, but those methods referenced an undeclared
  # `localizations` attribute and raised NameError on every call.
  # Removed 2026-07-05.
  class MinutesSection < Lutaml::Model::Serializable
    attribute :number, :string
    attribute :title, LocalizedString, collection: true
    attribute :narrative, LocalizedString, collection: true
    attribute :page_start, :integer
    attribute :page_end, :integer
    attribute :references, Reference, collection: true
  end
end
