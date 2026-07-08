# frozen_string_literal: true

module Edoxen
  # One language-specific value of a translatable String field.
  # Replaces the v2.x pattern of a separate MeetingLocalization/
  # Localization/ComponentLocalization object that duplicated the
  # entity's translatable fields.
  #
  # `spelling` is an ISO 24229 spelling/conversion system code:
  #   - Spelling system:   {lang}-{script}[-{country}][-{extension}]
  #                        e.g. `eng`, `zho-Hans`, `ind-Latn-pre1972`
  #   - Conversion system: {authority}:{source}:{target}:{identifying}
  #                        e.g. `acadsin:zho-Hani:Latn:2002`
  #
  # Always verbose — single-language data uses the same
  # `[{ spelling, value }]` shape as multi-language data.
  class LocalizedString < Lutaml::Model::Serializable
    attribute :spelling, :string
    attribute :value, :string
    attribute :extensions, MeetingExtension, collection: true
  end
end
