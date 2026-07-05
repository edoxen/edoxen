# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::DecisionMetadata do
  it_behaves_like "extension host", factory: {}

  describe "canonical fields" do
    it "carries title, date, source, source_urls, city, country_code" do
      payload = {
        "title" => "Decisions of the 38th plenary meeting of ISO/TC 154",
        "date" => "2019-10-17",
        "source" => "ISO/TC 154 Secretariat",
        "source_urls" => [
          { "ref" => "https://example.com/file.pdf", "format" => "pdf", "language_code" => "eng" }
        ],
        "city" => "LUX",
        "country_code" => "LU"
      }
      m = described_class.from_yaml(YAML.dump(payload))
      expect(m.title).to eq("Decisions of the 38th plenary meeting of ISO/TC 154")
      expect(m.date).to eq(Date.new(2019, 10, 17))
      expect(m.source).to eq("ISO/TC 154 Secretariat")
      expect(m.source_urls).to all(be_a(Edoxen::SourceUrl))
      expect(m.city).to eq("LUX")
      expect(m.country_code).to eq("LU")
    end

    it "supports title_localized[] for multilingual collections" do
      payload = {
        "title" => "Default",
        "title_localized" => [
          { "language_code" => "eng", "script" => "Latn", "title" => "English title" },
          { "language_code" => "fra", "script" => "Latn", "title" => "Titre français" }
        ]
      }
      m = described_class.from_yaml(YAML.dump(payload))
      expect(m.title_localized.size).to eq(2)
      expect(m.title_localized).to all(be_a(Edoxen::Localization))
      expect(m.title_localized.map(&:language_code)).to eq(%w[eng fra])
      expect(m.title_localized.map(&:title)).to eq(["English title", "Titre français"])
    end

    it "carries meeting_urn back-reference" do
      m = described_class.new(meeting_urn: "urn:edoxen:meeting:38")
      expect(m.meeting_urn).to eq("urn:edoxen:meeting:38")
    end
  end

  describe "#city_entry" do
    it "resolves the UN/LOCODE via Edoxen::ReferenceData" do
      entry = Struct.new(:code, :name, :country).new("FRPAR", "Paris", "FR")
      allow(Edoxen::ReferenceData).to receive(:find_unlocode).with("FRPAR").and_return(entry)

      m = described_class.new(city: "FRPAR")
      expect(m.city_entry.code).to eq("FRPAR")
    end

    it "returns nil when city is empty" do
      m = described_class.new(city: nil)
      expect(m.city_entry).to be_nil
    end
  end
end
