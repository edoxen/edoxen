# frozen_string_literal: true

module Edoxen
  # Mixed into entities that carry a per-language `localizations[]`
  # collection. Provides `in_language(code, fallback:)` and
  # `primary_localization` in one place so Decision, Meeting, etc.
  # share a single implementation.
  #
  # The including class must declare a typed `localizations` attribute
  # whose entries expose `language_code` (ISO 639-3).
  module LocalizationHost
    def in_language(code, fallback: false)
      match = localizations&.find { |loc| loc.language_code == code.to_s }
      return match if match

      fallback ? localizations&.first : nil
    end

    def primary_localization
      in_language("eng", fallback: true)
    end
  end
end
