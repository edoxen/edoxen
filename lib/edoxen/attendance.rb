# frozen_string_literal: true

module Edoxen
  # One attendance record per person. Combines:
  #   - status: ParticipationStatus (in-meeting observation: present/absent/
  #             apologies/observer/excused)
  #   - role: AttendanceRole (structural importance: chair/required/optional/
  #           non_participant — from iCalendar ROLE, plain English)
  #   - response: AttendanceResponse (RSVP state: pending/confirmed/declined/
  #               tentative/delegated — from iCalendar PARTSTAT, plain English)
  class Attendance < Lutaml::Model::Serializable
    attribute :person, Person
    attribute :status, :string, values: Enums::PARTICIPATION_STATUS
    attribute :role, :string, values: Enums::ATTENDANCE_ROLE
    attribute :response, :string, values: Enums::ATTENDANCE_RESPONSE
    attribute :affiliation, :string
    attribute :proxy_for, Person
    attribute :notes, :string
    attribute :extensions, MeetingExtension, collection: true

    key_value do
      map "person", to: :person
      map "status", to: :status
      map "role", to: :role
      map "response", to: :response
      map "affiliation", to: :affiliation
      map "proxy_for", to: :proxy_for
      map "notes", to: :notes
      map "extensions", to: :extensions
    end

    def present?
      status == "present"
    end

    def declined?
      response == "declined"
    end
  end
end
