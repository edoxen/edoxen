# frozen_string_literal: true

module Edoxen
  # Motion — a procedural act that brings a Decision. "I move that..."
  # Distinct from a Decision (formal outcome) and from a TopicDocument
  # (written text). A Motion does NOT require any document.
  #
  # State machine (MotionStatus):
  #   introduced → seconded → debating → question_put → voting
  #                                                ├── carried → resulting_decision set
  #                                                ├── negatived
  #                                                ├── withdrawn
  #                                                └── lapsed
  class Motion < Lutaml::Model::Serializable
    attribute :identifier, :string
    attribute :urn, :string
    attribute :text, :string
    attribute :mover, Person
    attribute :seconders, Person, collection: true
    attribute :status, :string, values: Enums::MOTION_STATUS
    attribute :introduced_at, :datetime
    attribute :proposed_decision, :string
    attribute :resulting_decision, :string
    attribute :votings, :string, collection: true
    attribute :extensions, MeetingExtension, collection: true

    def carried?
      status == "carried"
    end

    def pending?
      %w[introduced seconded debating question_put voting].include?(status)
    end
  end
end
