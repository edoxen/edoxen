# frozen_string_literal: true

module Edoxen
  # A structured decision identifier, e.g. prefix "ISO" + number "2019-01".
  # A Decision carries 1..* StructuredIdentifier so a single decision can
  # hold its TC number, its SC number, and any cross-cutting reference number
  # without forcing callers to flatten them into one opaque string.
  class StructuredIdentifier < Lutaml::Model::Serializable
    attribute :prefix, :string
    attribute :number, :string
  end
end
