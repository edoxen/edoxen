# frozen_string_literal: true

module Edoxen
  # One language-specific value of a translatable Name field.
  # Mirrors LocalizedString but carries a structured Name value rather
  # than a plain String.
  #
  # Use case: a single Contact can be known by different names in
  # different languages — `张建方` (zho-Hans) and `Jianfang Zhang`
  # (acadsin:zho-Hani:Latn:2002 Pinyin romanization) are the same person.
  class LocalizedName < Lutaml::Model::Serializable
    attribute :spelling, :string
    attribute :value, Name
    attribute :extensions, MeetingExtension, collection: true
  end
end
