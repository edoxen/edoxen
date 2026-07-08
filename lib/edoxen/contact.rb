# frozen_string_literal: true

module Edoxen
  # VCARD-like abstract contact. Generalises Person for cases where the
  # contact may be a person, an organisation, a department, a role
  # ("Secretariat"), or any other entity with a name and one or more
  # communication channels.
  #
  # 1.0 (per-field localization, ISO 24229):
  #   - All translatable fields are Localized<String/Name>[0..*]
  #     (one entry per spelling/conversion system code).
  #   - Added: `urn` for registry storage; `ref` for reference-by-URN.
  #
  # Reference vs inline: when `ref` is set, treat this Contact as a
  # reference (other fields ignored). When `ref` is unset, the Contact
  # is inline (full data). Both patterns are valid on every field that
  # accepts a Contact.
  class Contact < Lutaml::Model::Serializable
    attribute :ref, :string
    attribute :urn, :string
    attribute :name, LocalizedName, collection: true
    attribute :kind, :string
    attribute :role, :string
    attribute :title, LocalizedString, collection: true
    attribute :affiliation, LocalizedString, collection: true
    attribute :contact_methods, ContactMethod, collection: true
    attribute :identifiers, ContactIdentifier, collection: true
    attribute :address, LocalizedString, collection: true
    attribute :extensions, MeetingExtension, collection: true

    def reference?
      !ref.nil? && !ref.to_s.empty?
    end

    # Convenience: returns the LocalizedName value for a given spelling,
    # or the first one if no match. Returns a Name object (or nil).
    def name_in(spelling, fallback: true)
      entry = name&.find { |n| n.spelling == spelling.to_s }
      entry ||= name&.first if fallback
      entry&.value
    end

    # Convenience: returns the LocalizedString value for a given field
    # and spelling. Used internally by per-field helpers.
    def localized_value(field, spelling, fallback: true)
      list = public_send(field)
      return nil if list.nil? || list.empty?

      entry = list.find { |l| l.spelling == spelling.to_s }
      entry ||= list.first if fallback
      entry&.value
    end
  end
end
