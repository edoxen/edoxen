# frozen_string_literal: true

module Edoxen
  # Venue — polymorphic base class for places where a Meeting happens.
  # `kind` discriminates between physical and virtual; the type-specific
  # fields live on PhysicalVenue / VirtualVenue subclasses.
  #
  # Replaces v0.x `Location` (physical-only) and `Meeting.virtual: Boolean`
  # (insufficient — Zoom needs URL+passcode+dial-in).
  class Venue < Lutaml::Model::Serializable
    attribute :kind, :string, values: Enums::VENUE_KIND
    attribute :name, :string
    attribute :label, :string
    attribute :description, :string
    attribute :capacity, :integer
    attribute :url, :string
    attribute :extensions, MeetingExtension, collection: true

    def physical?
      kind == "physical"
    end

    def virtual?
      kind == "virtual"
    end
  end
end
