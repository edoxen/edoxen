# frozen_string_literal: true

module Edoxen
  # A formal declaration made by one or more meeting members.
  # Covers the two BS 0:2006 declaration types via the `kind`
  # discriminator: `conflict_of_interest` and `ipr`.
  #
  # The IPR-specific fields (`ipr_subject_ref`, `ipr_target_ref`)
  # are populated only when `kind == "ipr"`. This mirrors edoxen's
  # "flat class, kind discriminates which subset is populated"
  # pattern (cf. Venue: physical + virtual fields on one flat
  # class).
  #
  # Attachment points: `Meeting#declarations[]` (per-meeting) and
  # `Topic#declarations[]` (standing position that travels with
  # the topic).
  class Declaration < Lutaml::Model::Serializable
    attribute :kind, :string, values: Enums::DECLARATION_KIND
    attribute :description, LocalizedString, collection: true
    attribute :party, Person, collection: true
    attribute :ipr_subject_ref, EntityRef
    attribute :ipr_target_ref, EntityRef
    attribute :extensions, MeetingExtension, collection: true
  end
end
