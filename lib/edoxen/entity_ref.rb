# frozen_string_literal: true

module Edoxen
  # EntityRef — a typed cross-reference between entities (1.0, 1.0 design review).
  #
  # Single identity: exactly one of `urn`, `identifier`, or `local_ref`
  # must be set. Optional metadata: `kind`, `role`, `note`.
  #
  # Encapsulation:
  #   - Read the identity via `#resolved_identity` (returns the canonical
  #     form — URN string, StructuredIdentifier, or local key).
  #   - Validate via `#valid?` (true when exactly one identity field is
  #     set; `#multiple_identities?` flags the rare ambiguous case).
  #
  # Pilot: `Motion.resulting_decision_ref` (parallel to the existing
  # `resulting_decision: String`). 1.0 will remove the String form.
  class EntityRef < Lutaml::Model::Serializable
    attribute :urn, :string
    attribute :identifier, StructuredIdentifier
    attribute :local_ref, :string

    attribute :kind, :string
    attribute :role, :string
    attribute :note, :string

    # True when exactly one identity field is set. The wire contract
    # (1.0 design review + JSON-Schema) is XOR: setting 0 or ≥2 identity
    # fields is a data error.
    def valid?
      identities_set.size == 1
    end

    # True when two or more identity fields are set. Useful for
    # migration tooling that wants to warn on ambiguity without
    # rejecting outright.
    def multiple_identities?
      identities_set.size > 1
    end

    # Returns the canonical identity (URN > identifier > local_ref
    # precedence). Callers that need a single value should validate
    # first via `#valid?`; on a multiple-identity ref the precedence
    # is still applied but the data is suspect.
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
        case value
        when nil then true
        when String then value.empty?
        else false
        end
      end
    end
  end
end
