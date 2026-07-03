# frozen_string_literal: true

module Edoxen
  # Recurrence — structured representation of ISO 8601-2 §13 recurring
  # time intervals. QUERYABLE (each BYxxx part is its own attribute).
  #
  # Round-trip to/from ISO 8601-2 wire string is handled by adapters
  # in ReferenceData (NOT hand-rolled to_h — declared via lutaml-model
  # mapping).
  class Recurrence < Lutaml::Model::Serializable
    attribute :freq, :string, values: Enums::RECURRENCE_FREQ
    attribute :interval, :integer, default: 1
    attribute :count, :integer
    attribute :until, :datetime
    attribute :by_day, RecurrenceByDay, collection: true
    attribute :by_month_day, :integer, collection: true
    attribute :by_month, :integer, collection: true
    attribute :by_week_no, :integer, collection: true
    attribute :by_year_day, :integer, collection: true
    attribute :by_hour, :integer, collection: true
    attribute :by_minute, :integer, collection: true
    attribute :by_second, :integer, collection: true
    attribute :by_set_pos, :integer, collection: true
    attribute :week_start, :string, default: "MO"
    attribute :extensions, MeetingExtension, collection: true
  end
end
