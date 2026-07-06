# frozen_string_literal: true

module Edoxen
  # Structured personal/organisational name. VCARD conventions
  # (RFC 6350): separate structured components (N) from a pre-formatted
  # display string (FN). Either or both may be populated.
  #
  # `formatted` is the display string when callers have it pre-built;
  # the structured fields (`family`, `given`, `additional`, `prefix`,
  # `suffix`) let adopters store parsed components for sorting, indexing,
  # or locale-aware rendering.
  class Name < Lutaml::Model::Serializable
    attribute :formatted, :string
    attribute :family, :string
    attribute :given, :string
    attribute :additional, :string
    attribute :prefix, :string
    attribute :suffix, :string
    attribute :extensions, MeetingExtension, collection: true

    # Convenience: returns `formatted` if present, else builds one from
    # the structured components. Useful for callers that always want a
    # display string regardless of how the name was authored.
    def display
      formatted || [prefix, given, additional, family, suffix]
        .reject(&:nil?).reject { |s| s.to_s.empty? }.join(" ")
    end
  end
end
