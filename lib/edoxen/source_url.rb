# frozen_string_literal: true

module Edoxen
  # Per-language canonical source URL (e.g. one PDF per language).
  # Carries the URL ref, its format, the ISO 639-3 language_code the URL
  # is the canonical source for, and an optional `kind` discriminator
  # (agenda_pdf, minutes_pdf, decisions_pdf, ...) used by the Meeting
  # model. Existing fixtures without `kind` still parse — the field is
  # optional.
  class SourceUrl < Lutaml::Model::Serializable
    attribute :ref, :string
    attribute :format, :string
    attribute :language_code, :string
    attribute :kind, :string, values: Enums::SOURCE_URL_KIND
  end
end
