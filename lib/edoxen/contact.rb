# frozen_string_literal: true

module Edoxen
  # VCARD-like abstract contact. Generalises Person for cases where the
  # contact may be a person, an organisation, a department, a role
  # ("Secretariat"), or any other entity with a name and one or more
  # communication channels.
  #
  # Use Contact where the kind of contact is open or mixed (meeting
  # local-contact, meeting-series organiser, host-ref contact). Use
  # Person (which inherits from Contact) where the contact is
  # specifically an individual with identity (officer, attendee, voter).
  class Contact < Lutaml::Model::Serializable
    attribute :name, Name
    attribute :kind, :string
    attribute :role, :string
    attribute :title, :string
    attribute :affiliation, :string
    attribute :contact_methods, ContactMethod, collection: true
    attribute :identifiers, ContactIdentifier, collection: true
    attribute :address, :string
    attribute :extensions, MeetingExtension, collection: true
  end
end
