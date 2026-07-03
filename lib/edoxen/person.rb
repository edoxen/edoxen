# frozen_string_literal: true

module Edoxen
  # Identity + role + affiliation + contact + kind. Used for meeting officers
  # (chair, secretary, local contact), host-ref contacts, and meeting
  # participants.
  #
  # `kind` is open for adopter-defined values: member, public_officer,
  # presiding_officer, clerk, witness, expert, etc.
  class Person < Lutaml::Model::Serializable
    attribute :name, :string
    attribute :kind, :string
    attribute :role, :string
    attribute :affiliation, :string
    attribute :email, :string
    attribute :phone, :string
    attribute :orcid, :string
    attribute :extensions, MeetingExtension, collection: true
  end
end
