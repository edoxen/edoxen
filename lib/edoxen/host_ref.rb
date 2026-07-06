# frozen_string_literal: true

module Edoxen
  # Typed reference to an organization that hosts or co-organizes a
  # meeting. `ref` is a stable identifier into an external registry
  # (national_bodies.yml, liaisons.yml, associates.yml in ISO/TC 154);
  # `type` discriminates which registry.
  class HostRef < Lutaml::Model::Serializable
    attribute :ref, :string
    attribute :type, :string, values: Enums::HOST_TYPE
    attribute :role, :string
    attribute :contact, Contact
  end
end
