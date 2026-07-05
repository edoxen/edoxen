# frozen_string_literal: true

module Edoxen
  # EntityRef — a typed cross-reference between entities (v2.1, TODO.refactor/44).
  #
  # Single identity: exactly one of `urn`, `identifier`, or `local_ref`
  # should be set. Optional metadata: `kind`, `role`, `note`.
  #
  # Encapsulation:
  #   - Read the identity via `#resolved_identity` (returns the canonical
  #     form — URN string, StructuredIdentifier, or local key).
  #   - Validate via `#valid?` (true when at least one identity field is
  #     set; the schema mirrors this for YAML consumers).
  #
  # Pilot: `Motion.resulting_decision_ref` (parallel to the existing
  # `resulting_decision: String`). v3.0 will remove the String form.
  class EntityRef < Lutaml::Model::Serializable
    attribute :urn, :string
    attribute :identifier, StructuredIdentifier
    attribute :local_ref, :string

    attribute :kind, :string
    attribute :role, :string
    attribute :note, :string

    key_value do
      map "urn", to: :urn
      map "identifier", to: :identifier
      map "local_ref", to: :local_ref
      map "kind", to: :kind
      map "role", to: :role
      map "note", to: :note
    end

    def valid?
      identities_set.any?
    end

    def resolved_identity
      return urn if urn && !urn.to_s.empty?
      return identifier if identifier
      return local_ref if local_ref && !local_ref.to_s.empty?

      nil
    end

    def to_s
      identity = resolved_identity
      return "(invalid EntityRef)" unless identity

      case identity
      when StructuredIdentifier then "#{identity.prefix}/#{identity.number}"
      else identity.to_s
      end
    end

    private

    def identities_set
      [urn, identifier, local_ref].reject do |value|
        value.nil? || (value.respond_to?(:to_s) && value.to_s.empty?)
      end
    end
  end
end
