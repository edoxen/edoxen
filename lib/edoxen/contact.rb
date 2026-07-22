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
    attribute :local_ref, :string
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
      (!ref.nil? && !ref.to_s.empty?) ||
        (!local_ref.nil? && !local_ref.to_s.empty?)
    end

    # Key used to resolve a +local_ref+ against a document-scoped
    # collection (e.g. Meeting#contacts[]). Contacts are keyed by urn.
    def local_lookup_key
      urn
    end
  end
end
