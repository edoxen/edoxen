# frozen_string_literal: true

module Edoxen
  # EntityResolver — resolves Contact/Venue/Body references by walking
  # the three-tier scope hierarchy:
  #
  #   1. Inline: if the entity has no +ref+ and no +local_ref+, return
  #      it as-is (it carries full data).
  #   2. Document-scoped: if +local_ref+ is set, look up in the
  #      document-scoped collection (e.g. Meeting#contacts) by matching
  #      the member's +local_lookup_key+ against +local_ref+.
  #   3. Global register: if +ref+ is set, look up in the global
  #      register (e.g. ContactRegister) by matching +urn+ against +ref+.
  #
  # Pure service: no mutation. Returns the resolved entity or nil.
  class EntityResolver
    attr_reader :scoped_collections, :global_registers

    def initialize(scoped: {}, registers: {})
      @scoped_collections = scoped
      @global_registers = registers
    end

    def resolve(entity)
      return entity unless entity.reference?

      resolve_local(entity) || resolve_global(entity)
    end

    def resolve_all(entities)
      entities.map { |e| resolve(e) }
    end

    private

    def resolve_local(entity)
      return nil if entity.local_ref.nil? || entity.local_ref.to_s.empty?

      collection = find_scoped_collection(entity.class)
      return nil unless collection

      collection.find { |member| member.local_lookup_key == entity.local_ref }
    end

    def resolve_global(entity)
      return nil if entity.ref.nil? || entity.ref.to_s.empty?

      register = find_global_register(entity.class)
      return nil unless register

      register.find_by_urn(entity.ref)
    end

    def find_scoped_collection(klass)
      @scoped_collections[klass] ||
        @scoped_collections[klass.superclass]
    end

    def find_global_register(klass)
      @global_registers[klass] ||
        @global_registers[klass.superclass]
    end
  end
end
