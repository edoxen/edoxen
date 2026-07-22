# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::Venue do
  it_behaves_like "extension host", factory: {}

  describe "kind discriminator" do
    it "is physical? when kind=physical" do
      v = described_class.new(kind: "physical", name: "Hall")
      expect(v).to be_physical
      expect(v).not_to be_virtual
    end

    it "is virtual? when kind=virtual" do
      v = described_class.new(kind: "virtual", name: "Zoom")
      expect(v).to be_virtual
      expect(v).not_to be_physical
    end
  end

  it "carries physical-venue fields" do
    payload = {
      "kind" => "physical",
      "name" => [{ "spelling" => "eng", "value" => "Acme HQ" }],
      "unlocode" => "USNYC",
      "iata_code" => "JFK",
      "address" => [{ "spelling" => "eng", "value" => "1 Acme Plaza" }],
      "country_code" => "US",
      "lat" => 40.7128,
      "lon" => -74.0060,
      "building" => [{ "spelling" => "eng", "value" => "Tower" }],
      "floor" => [{ "spelling" => "eng", "value" => "10" }],
      "room" => [{ "spelling" => "eng", "value" => "A" }]
    }
    v = described_class.from_yaml(YAML.dump(payload))
    expect(v.unlocode).to eq("USNYC")
    expect(v.iata_code).to eq("JFK")
    expect(v.country_code).to eq("US")
    expect(v.lat).to eq(40.7128)
  end

  it "carries virtual-venue fields" do
    payload = {
      "kind" => "virtual",
      "name" => [{ "spelling" => "eng", "value" => "Zoom" }],
      "uri" => "https://zoom.us/j/123",
      "features" => %w[audio video],
      "passcode" => "1234",
      "meeting_id" => "987654",
      "waiting_room" => true
    }
    v = described_class.from_yaml(YAML.dump(payload))
    expect(v.uri).to eq("https://zoom.us/j/123")
    expect(v.features).to eq(%w[audio video])
    expect(v.passcode).to eq("1234")
    expect(v.meeting_id).to eq("987654")
    expect(v.waiting_room).to be true
  end

  describe "#features_list" do
    it "joins features with comma-space" do
      expect(described_class.new(features: %w[audio video chat]).features_list).to eq("audio, video, chat")
    end

    it "returns empty string when features is nil" do
      expect(described_class.new.features_list).to eq("")
    end
  end

  describe "#unlocode_entry / #iata_entry" do
    it "delegates to Edoxen::ReferenceData" do
      entry = Struct.new(:code, :name).new("FRPAR", "Paris")
      allow(Edoxen::ReferenceData).to receive(:find_unlocode).with("FRPAR").and_return(entry)
      v = described_class.new(unlocode: "FRPAR")
      expect(v.unlocode_entry.code).to eq("FRPAR")
    end

    it "returns nil when code is empty" do
      expect(described_class.new.unlocode_entry).to be_nil
      expect(described_class.new.iata_entry).to be_nil
    end
  end

  describe "#local_lookup_key" do
    it "returns the urn (Venues are keyed by urn in scoped collections)" do
      v = described_class.new(urn: "urn:edoxen:venue:test:grand-hall")
      expect(v.local_lookup_key).to eq("urn:edoxen:venue:test:grand-hall")
    end

    it "is nil when no urn is set" do
      expect(described_class.new.local_lookup_key).to be_nil
    end
  end
end

RSpec.describe Edoxen::PhysicalVenue do
  it "default kind is physical" do
    expect(described_class.new.kind).to eq("physical")
  end

  it "is a Venue" do
    expect(described_class.new).to be_a(Edoxen::Venue)
  end
end

RSpec.describe Edoxen::VirtualVenue do
  it "default kind is virtual" do
    expect(described_class.new.kind).to eq("virtual")
  end

  it "is a Venue" do
    expect(described_class.new).to be_a(Edoxen::Venue)
  end
end
