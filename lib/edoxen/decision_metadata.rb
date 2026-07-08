# frozen_string_literal: true

module Edoxen
  # Collection-level metadata: the localized title, the meeting date,
  # the source secretariat, per-language source PDFs, and the host venue.
  class DecisionMetadata < Lutaml::Model::Serializable
    include BodyVocabularyHost

    attribute :title, LocalizedString, collection: true
    attribute :date, :date
    attribute :source, :string
    attribute :source_urls, SourceUrl, collection: true
    attribute :city, :string
    attribute :country_code, :string

    # URN back-reference to the Meeting that produced this collection.
    attribute :meeting_urn, :string

    attribute :extensions, MeetingExtension, collection: true

    def title_in(spelling, fallback: true)
      entry = title&.find { |l| l.spelling == spelling.to_s }
      entry ||= title&.first if fallback
      entry&.value
    end

    def city_entry
      return nil if city.nil? || city.to_s.empty?

      Edoxen::ReferenceData.find_unlocode(city)
    end
  end
end
