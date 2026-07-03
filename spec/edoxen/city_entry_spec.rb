# frozen_string_literal: true

require "spec_helper"

RSpec.describe "city_entry lookups" do
  describe Edoxen::Meeting, "#city_entry" do
    it "returns an Unlocodes::Entry for a known UN/LOCODE" do
      meeting = described_class.new(
        identifier: [Edoxen::StructuredIdentifier.new(prefix: "X", number: "1")],
        type: "plenary",
        city: "FRPAR"
      )
      entry = meeting.city_entry
      expect(entry).to be_a(Unlocodes::Entry)
      expect(entry.code).to eq("FRPAR")
      expect(entry.name).to eq("Paris")
    end

    it "returns nil when city is empty" do
      meeting = described_class.new(
        identifier: [Edoxen::StructuredIdentifier.new(prefix: "X", number: "1")],
        type: "plenary",
        city: ""
      )
      expect(meeting.city_entry).to be_nil
    end

    it "returns nil when city is nil" do
      meeting = described_class.new(
        identifier: [Edoxen::StructuredIdentifier.new(prefix: "X", number: "1")],
        type: "plenary"
      )
      expect(meeting.city_entry).to be_nil
    end

    it "returns nil when the code is not in the registry" do
      meeting = described_class.new(
        identifier: [Edoxen::StructuredIdentifier.new(prefix: "X", number: "1")],
        type: "plenary",
        city: "ZZZZZ"
      )
      expect(meeting.city_entry).to be_nil
    end
  end

  describe Edoxen::DecisionMetadata, "#city_entry" do
    it "returns an Unlocodes::Entry for a known UN/LOCODE" do
      md = described_class.new(city: "HKHKG")
      entry = md.city_entry
      expect(entry).to be_a(Unlocodes::Entry)
      expect(entry.country).to eq("HK")
    end

    it "returns nil when city is empty" do
      expect(described_class.new(city: "").city_entry).to be_nil
    end

    it "returns nil when city is nil" do
      expect(described_class.new.city_entry).to be_nil
    end
  end
end
