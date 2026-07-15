# frozen_string_literal: true

module Edoxen
  # Authoritative register of Bodies (committees, subcommittees, working
  # groups). Members carry `urn: urn:edoxen:body:{scope}:{local-id}`;
  # the register's +scope+ MUST match the scope segment in member URNs.
  class BodyRegister < Lutaml::Model::Serializable
    attribute :scope, :string
    attribute :title, LocalizedString, collection: true
    attribute :bodies, Body, collection: true
    attribute :extensions, MeetingExtension, collection: true

    def find_by_urn(urn)
      bodies&.find { |b| b.code == urn || b.ref == urn }
    end
  end
end
