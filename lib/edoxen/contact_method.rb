# frozen_string_literal: true

module Edoxen
  # One polymorphic communication channel — phone, email, fax, url, mail,
  # etc. Replaces the hard-coded `email` / `phone` fields that used to
  # live on Person and Venue. New channel kinds are added via the
  # ContactMethodKind enum (or `other` + extensions for adopter-specific
  # channels); the model itself never needs to change (OCP).
  class ContactMethod < Lutaml::Model::Serializable
    attribute :kind, :string, values: Enums::CONTACT_METHOD_KIND
    attribute :value, :string
    attribute :label, :string
    attribute :primary, :boolean
    attribute :extensions, MeetingExtension, collection: true
  end
end
