# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::VenueValidator do
  describe "physical venue" do
    it "is valid when the UN/LOCODE is known" do
      entry = Struct.new(:code, :name, :country).new("FRPAR", "Paris", "FR")
      allow(Edoxen::ReferenceData).to receive(:find_unlocode).with("FRPAR").and_return(entry)
      venue = Edoxen::PhysicalVenue.new(unlocode: "FRPAR")
      validator = described_class.new(venue)
      expect(validator).to be_valid
    end

    it "records an error when the UN/LOCODE is unknown" do
      allow(Edoxen::ReferenceData).to receive(:find_unlocode).with("ZZZZZ").and_return(nil)
      venue = Edoxen::PhysicalVenue.new(unlocode: "ZZZZZ")
      validator = described_class.new(venue)
      expect(validator).not_to be_valid
      expect(validator.errors).to include("Unknown UN/LOCODE: ZZZZZ")
    end

    it "auto-populates city and country_code when asked" do
      entry = Struct.new(:code, :name, :country).new("FRPAR", "Paris", "FR")
      allow(Edoxen::ReferenceData).to receive(:find_unlocode).with("FRPAR").and_return(entry)
      venue = Edoxen::PhysicalVenue.new(unlocode: "FRPAR")
      validator = described_class.new(venue)
      validator.validate(auto_populate: true)
      expect(venue.city).to eq("Paris")
      expect(venue.country_code).to eq("FR")
    end

    it "validates IATA code" do
      allow(Edoxen::ReferenceData).to receive(:find_iata).with("JFK").and_return(nil)
      venue = Edoxen::PhysicalVenue.new(iata_code: "JFK")
      validator = described_class.new(venue)
      expect(validator).not_to be_valid
      expect(validator.errors).to include("Unknown IATA code: JFK")
    end
  end

  describe "virtual venue" do
    it "is always valid (no UN/LOCODE to check)" do
      venue = Edoxen::VirtualVenue.new(uri: "https://zoom.us/j/123")
      validator = described_class.new(venue)
      expect(validator).to be_valid
    end
  end

  describe "flat Venue dispatched by kind (not by subclass)" do
    # Regression for the is_a?(PhysicalVenue) bug: anything parsed from
    # YAML is a flat Venue regardless of `kind`. The validator must
    # dispatch on `kind`, not on Ruby subclass, or every venue parsed
    # from a real meeting file silently skips validation.
    it "validates a flat Venue with kind=physical and bad UN/LOCODE" do
      allow(Edoxen::ReferenceData).to receive(:find_unlocode).with("ZZZZZ").and_return(nil)
      venue = Edoxen::Venue.new(kind: "physical", unlocode: "ZZZZZ")
      validator = described_class.new(venue)
      expect(validator).not_to be_valid
      expect(validator.errors).to include("Unknown UN/LOCODE: ZZZZZ")
    end

    it "validates a flat Venue with kind=physical and good UN/LOCODE" do
      entry = Struct.new(:code, :name, :country).new("FRPAR", "Paris", "FR")
      allow(Edoxen::ReferenceData).to receive(:find_unlocode).with("FRPAR").and_return(entry)
      venue = Edoxen::Venue.from_yaml(YAML.dump("kind" => "physical", "unlocode" => "FRPAR"))
      expect(described_class.new(venue)).to be_valid
    end

    it "skips validation for a flat Venue with kind=virtual" do
      venue = Edoxen::Venue.new(kind: "virtual", uri: "https://zoom.us/j/1")
      expect(described_class.new(venue)).to be_valid
    end
  end
end
