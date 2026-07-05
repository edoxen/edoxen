# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::ReferenceData do
  it "freezes every list so callers cannot mutate" do
    described_class.constants(false).each do |name|
      expect(described_class.const_get(name)).to be_frozen,
                                                 "Edoxen::ReferenceData::#{name} must be frozen"
    end
  end

  it "has no duplicates within a list" do
    described_class.constants(false).each do |name|
      values = described_class.const_get(name)
      dups = values.tally.select { |_, n| n > 1 }.keys
      expect(dups).to be_empty, "Edoxen::ReferenceData::#{name} has duplicates: #{dups.inspect}"
    end
  end

  it "carries the codes the fixtures actually use" do
    expect(described_class::COUNTRY_CODES).to include("FR", "DE", "CN", "HK", "TH")
    expect(described_class::LANGUAGE_CODES).to include("eng", "fra", "deu", "rus")
    expect(described_class::SCRIPT_CODES).to include("Latn", "Cyrl", "Hant")
  end

  it "matches ISO 3166-1 alpha-2 shape (two uppercase letters)" do
    described_class::COUNTRY_CODES.each do |c|
      expect(c).to match(/\A[A-Z]{2}\z/), "#{c.inspect} is not alpha-2"
    end
  end

  it "matches ISO 639-3 shape (three lowercase letters)" do
    described_class::LANGUAGE_CODES.each do |c|
      expect(c).to match(/\A[a-z]{3}\z/), "#{c.inspect} is not three-letter lowercase"
    end
  end

  it "matches ISO 15924 shape (capital + three lowercase letters)" do
    described_class::SCRIPT_CODES.each do |c|
      expect(c).to match(/\A[A-Z][a-z]{3}\z/), "#{c.inspect} is not ISO 15924 shape"
    end
  end

  it "matches UN/LOCODE shape (2-letter country + 3-char location)" do
    described_class::UNLOCODES.each do |c|
      expect(c).to match(/\A[A-Z]{2}[A-Z0-9]{3}\z/),
                   "#{c.inspect} is not UN/LOCODE shape (5-char uppercase)"
    end
  end

  it "exposes UN/LOCODEs for cities the fixtures actually use" do
    expect(described_class::UNLOCODES).to include("FRPAR", "HKHKG", "LULUX", "CNSHA", "THCNM")
  end

  it "derives the country code from every UN/LOCODE correctly" do
    described_class::UNLOCODES.each do |loc|
      country = loc[0, 2]
      expect(described_class::COUNTRY_CODES).to include(country),
                                                "UN/LOCODE #{loc} prefixes country #{country} not in COUNTRY_CODES"
    end
  end

  describe ".find_unlocode" do
    it "returns an Unlocodes::Entry for a known code" do
      entry = described_class.find_unlocode("FRPAR")
      expect(entry).to be_a(Unlocodes::Entry)
      expect(entry.code).to eq("FRPAR")
      expect(entry.country).to eq("FR")
    end

    it "accepts lowercase input (coerces to uppercase)" do
      expect(described_class.find_unlocode("frpar")&.code).to eq("FRPAR")
    end

    it "returns nil for an unknown code" do
      expect(described_class.find_unlocode("ZZZZZ")).to be_nil
    end

    it "returns nil for empty input" do
      expect(described_class.find_unlocode("")).to be_nil
      expect(described_class.find_unlocode(nil)).to be_nil
    end
  end

  describe ".unlocode_exists?" do
    it "is true for a known code" do
      expect(described_class.unlocode_exists?("FRPAR")).to be true
    end

    it "is false for an unknown code" do
      expect(described_class.unlocode_exists?("ZZZZZ")).to be false
    end
  end
end
