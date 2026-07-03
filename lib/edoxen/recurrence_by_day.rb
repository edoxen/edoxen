# frozen_string_literal: true

module Edoxen
  # RecurrenceByDay — a BYDAY part of an ISO 8601-2 §13 recurrence.
  # `ordinal` is null for "every", +1 for "first", -1 for "last", etc.
  class RecurrenceByDay < Lutaml::Model::Serializable
    attribute :ordinal, :integer
    attribute :weekday, :string
  end
end
