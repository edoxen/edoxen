# frozen_string_literal: true

module Edoxen
  # A committee, subcommittee, working group, or other organised body
  # that owns meetings and decisions. Carries a short code (e.g.
  # "ISO/TC 154", "CIML") and a localised full name.
  #
  # Three-tier entity resolution (same pattern as Contact and Venue):
  # +ref+ set → resolve from global BodyRegister by URN.
  # +local_ref+ set → resolve from document-scoped Meeting#bodies[].
  # Both nil → inline data.
  class Body < Lutaml::Model::Serializable
    attribute :ref, :string
    attribute :local_ref, :string
    attribute :code, :string
    attribute :name, LocalizedString, collection: true
    attribute :kind, :string
    attribute :parent_ref, EntityRef
    attribute :extensions, MeetingExtension, collection: true

    def reference?
      (!ref.nil? && !ref.to_s.empty?) ||
        (!local_ref.nil? && !local_ref.to_s.empty?)
    end
  end
end
