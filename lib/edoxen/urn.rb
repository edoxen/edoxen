# frozen_string_literal: true

module Edoxen
  # Value object for Edoxen scoped URNs. The wire format is always
  # `urn:edoxen:{entity}:{scope}:{local-id}` — e.g.
  # `urn:edoxen:contact:isotc154:jianfang-zhang`.
  #
  # This class is a helper for parsing, formatting, and validating URN
  # strings. The model stores URNs as plain `:string` attributes —
  # callers convert to/from Urn when they need to inspect segments.
  class Urn
    NAMESPACE = "edoxen"
    PATTERN = /\Aurn:edoxen:(?<entity>[a-z][a-z0-9_-]*):(?<scope>[a-z][a-z0-9_-]*):(?<id>[a-z0-9][a-z0-9_-]*)\z/i

    attr_reader :entity, :scope, :id

    def initialize(entity:, scope:, id:)
      @entity = entity
      @scope = scope
      @id = id
    end

    def to_s
      "#{NAMESPACE}:#{entity}:#{scope}:#{id}"
    end
    alias_method :to_str, :to_s

    def ==(other)
      other.is_a?(Urn) && to_s == other.to_s
    end
    alias_method :eql?, :==

    def hash
      to_s.hash
    end

    def self.parse(string)
      match = PATTERN.match(string.to_s)
      return nil unless match

      new(entity: match[:entity], scope: match[:scope], id: match[:id])
    end

    def self.format(entity:, scope:, id:)
      new(entity: entity, scope: scope, id: id).to_s
    end

    def self.valid?(string)
      PATTERN.match?(string.to_s)
    end
  end
end
