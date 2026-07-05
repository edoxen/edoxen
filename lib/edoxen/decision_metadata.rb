# frozen_string_literal: true

module Edoxen
  # Collection-level metadata: the title (string for default / single-language
  # collections, or `title_localized[]` for multilingual), the meeting date,
  # the source secretariat, per-language source PDFs, and the host venue.
  class DecisionMetadata < Lutaml::Model::Serializable
    attribute :title, :string
    attribute :title_localized, Localization, collection: true
    attribute :date, :date
    attribute :source, :string
    attribute :source_urls, SourceUrl, collection: true
    attribute :city, :string
    attribute :country_code, :string

    # URN back-reference to the Meeting that produced this collection.
    attribute :meeting_urn, :string

    # v2.1 (TODO.refactor/46): per-dataset body_vocabulary. SSOT for
    # body_type → canonical_type resolution within this collection.
    attribute :body_vocabulary, BodyVocabularyEntry, collection: true

    attribute :extensions, MeetingExtension, collection: true

    def city_entry
      return nil if city.nil? || city.to_s.empty?

      Edoxen::ReferenceData.find_unlocode(city)
    end

    # Resolve a body_type to its canonical_type via this collection's
    # vocabulary. Permissive — returns the body_type unchanged when no
    # matching entry exists (with no warning; v3.x adds strict mode).
    def canonical_type_for(body_type)
      return body_type if body_type.nil? || body_type.to_s.empty?
      return body_type unless body_vocabulary

      entry = body_vocabulary.find { |e| e.body_type == body_type }
      entry ? entry.canonical_type : body_type
    end
  end
end
