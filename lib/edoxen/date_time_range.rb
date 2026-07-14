# frozen_string_literal: true

module Edoxen
  # Start + end pair with sub-day precision. Parallel to DateRange;
  # use when day granularity is insufficient — e.g.
  # `Meeting#occurred_date_range` (a meeting that ran 09:00–11:30).
  #
  # The two are intentionally separate types so the granularity is
  # visible at the type level: a caller who sees DateRange knows
  # it is day-granularity; a caller who sees DateTimeRange knows
  # sub-day precision is available.
  class DateTimeRange < Lutaml::Model::Serializable
    attribute :start, :date_time
    attribute :end, :date_time
  end
end
