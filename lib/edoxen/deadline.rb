# frozen_string_literal: true

module Edoxen
  # A time-bound requirement leading up to (or following) a meeting —
  # registration cutoff, report-submission deadline, etc.
  class Deadline < Lutaml::Model::Serializable
    attribute :date, :date
    attribute :description, LocalizedString, collection: true
  end
end
