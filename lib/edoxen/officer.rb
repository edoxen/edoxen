# frozen_string_literal: true

module Edoxen
  # Officer — a person holding a structural role in a Meeting.
  # Replaces v0.x Meeting#chair and Meeting#secretary direct shortcuts.
  # One list, role discriminates. Open for adopter extension via `other`.
  class Officer < Lutaml::Model::Serializable
    attribute :role, :string, values: Enums::OFFICER_ROLE
    attribute :person, Person
    attribute :term_start, :date
    attribute :term_end, :date
    attribute :extensions, MeetingExtension, collection: true

    def current?(date = Date.today)
      (term_start.nil? || date >= term_start) &&
        (term_end.nil? || date <= term_end)
    end
  end
end
