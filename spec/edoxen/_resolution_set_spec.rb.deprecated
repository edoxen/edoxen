# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::ResolutionSet do
  let(:fixture_path) { File.join(__dir__, "..", "fixtures", "isotc154-plenary-38.yaml") }
  let(:fixture_yaml) { File.read(fixture_path) }
  let(:sample_collection) { described_class.from_yaml(fixture_yaml) }

  describe "attributes" do
    it "has the expected attributes" do
      collection = described_class.new

      expect(collection).to respond_to(:metadata)
      expect(collection).to respond_to(:resolutions)
    end
  end

  describe "metadata handling" do
    it "accepts Metadata objects" do
      expect(sample_collection.metadata).to be_a(Edoxen::Metadata)
      expect(sample_collection.metadata.title).to eq("Resolutions of the 38th plenary meeting of ISO/TC 154")
    end

    it "handles metadata with multiple dates" do
      expect(sample_collection.metadata.dates.length).to eq(1)
      expect(sample_collection.metadata.dates.first.kind).to eq("meeting")
      expect(sample_collection.metadata.dates.first.start.to_s).to eq("2019-10-17")
    end
  end

  describe "resolutions collection" do
    it "handles empty resolutions array" do
      collection = described_class.new(resolutions: [])
      expect(collection.resolutions).to be_an(Array)
      expect(collection.resolutions).to be_empty
    end

    it "handles array of Resolution objects" do
      expect(sample_collection.resolutions.length).to eq(22)
      expect(sample_collection.resolutions.first).to be_a(Edoxen::Resolution)
      expect(sample_collection.resolutions.first.title).to include("Adoption of NWIP ballot")
    end
  end

  describe "YAML serialization" do
    it "serializes to YAML correctly" do
      yaml_output = sample_collection.to_yaml

      expect(yaml_output).to include("metadata:")
      expect(yaml_output).to include("title: Resolutions of the 38th plenary meeting of ISO/TC 154")
      expect(yaml_output).to include("resolutions:")
      expect(yaml_output).to include("Adoption of NWIP ballot for ISO/PWI 9735-11")
      expect(yaml_output).to include("Approval of the Business Plan")
    end

    it "deserializes from YAML correctly" do
      yaml_output = sample_collection.to_yaml
      parsed_collection = described_class.from_yaml(yaml_output)

      expect(parsed_collection.metadata.title).to eq("Resolutions of the 38th plenary meeting of ISO/TC 154")
      expect(parsed_collection.resolutions.length).to eq(sample_collection.resolutions.length)
      expect(parsed_collection.resolutions.first.title).to include("Adoption of NWIP ballot")
      expect(parsed_collection.resolutions.last.title).to eq("Appreciation of the meeting host and all participants")
    end

    it "handles round-trip serialization" do
      yaml_output = sample_collection.to_yaml
      parsed_collection = described_class.from_yaml(yaml_output)
      second_yaml = parsed_collection.to_yaml

      expect(yaml_output).to eq(second_yaml)
    end
  end

  describe "real-world data compatibility" do
    it "loads real-world YAML data correctly" do
      expect(sample_collection.metadata.title).to eq("Resolutions of the 38th plenary meeting of ISO/TC 154")
      expect(sample_collection.metadata.dates.first.start.to_s).to eq("2019-10-17")
      expect(sample_collection.metadata.source).to eq("ISO/TC 154 Secretariat")

      expect(sample_collection.resolutions.length).to eq(22)

      first_resolution = sample_collection.resolutions.first
      expect(first_resolution.categories).to eq(["Resolutions related to JWG 1"])
      expect(first_resolution.identifier).to eq("2019-01")
      expect(first_resolution.considerations.length).to eq(3)
      expect(first_resolution.approvals.length).to eq(1)
      expect(first_resolution.actions.length).to eq(1)

      second_resolution = sample_collection.resolutions[1]
      expect(second_resolution.categories).to eq(["Resolutions related to JWG 1"])
      expect(second_resolution.identifier).to eq("2019-02")
      expect(second_resolution.actions.first.type).to eq("resolves")
    end

    it "preserves all data through round-trip" do
      yaml_output = sample_collection.to_yaml
      reparsed_collection = described_class.from_yaml(yaml_output)

      expect(reparsed_collection.metadata.title).to eq(sample_collection.metadata.title)
      expect(reparsed_collection.resolutions.length).to eq(sample_collection.resolutions.length)

      # Check that nested objects are preserved
      original_first = sample_collection.resolutions.first
      reparsed_first = reparsed_collection.resolutions.first

      expect(reparsed_first.considerations.length).to eq(original_first.considerations.length)
      expect(reparsed_first.approvals.length).to eq(original_first.approvals.length)
      expect(reparsed_first.actions.length).to eq(original_first.actions.length)
    end

    it "handles different types of resolutions" do
      # Test JWG 1 resolution
      jwg_resolution = sample_collection.resolutions.find { |r| r.identifier == "2019-01" }
      expect(jwg_resolution.categories).to eq(["Resolutions related to JWG 1"])
      expect(jwg_resolution.actions.first.type).to eq("resolves")

      # Test WG 5 resolution
      wg5_resolution = sample_collection.resolutions.find { |r| r.identifier == "2019-03" }
      expect(wg5_resolution.categories).to eq(["Resolutions related to WG 5"])
      expect(wg5_resolution.actions.first.type).to eq("requests")

      # Test General resolution
      general_resolution = sample_collection.resolutions.find { |r| r.identifier == "2019-20" }
      expect(general_resolution.categories).to eq(["General Resolutions"])
      expect(general_resolution.actions.first.type).to eq("approves")

      # Test Thanks resolution
      thanks_resolution = sample_collection.resolutions.find { |r| r.identifier == "2019-22" }
      expect(thanks_resolution.categories).to eq(["General Resolutions"])
      expect(thanks_resolution.actions.first.type).to eq("thanks")
      expect(thanks_resolution.actions.length).to eq(2)
    end
  end

  describe "edge cases" do
    it "handles collection with no metadata" do
      collection = described_class.new(resolutions: [])
      expect(collection.metadata).to be_nil
    end

    it "handles collection with no resolutions" do
      collection = described_class.new(
        metadata: Edoxen::Metadata.new(title: "Empty Collection")
      )
      expect(collection.resolutions).to be_nil
    end

    it "handles empty collection" do
      collection = described_class.new
      yaml_output = collection.to_yaml
      parsed_collection = described_class.from_yaml(yaml_output)

      expect(parsed_collection).to be_a(described_class)
    end
  end

  describe "JSON serialization" do
    it "serializes to JSON correctly" do
      json_output = sample_collection.to_json

      expect(json_output).to include('"title":"Resolutions of the 38th plenary meeting of ISO/TC 154"')
      expect(json_output).to include('"categories":["Resolutions related to JWG 1"]')
    end

    it "deserializes from JSON correctly" do
      json_output = sample_collection.to_json
      parsed_collection = described_class.from_json(json_output)

      expect(parsed_collection.metadata.title).to eq("Resolutions of the 38th plenary meeting of ISO/TC 154")
      expect(parsed_collection.resolutions.first.title).to include("Adoption of NWIP ballot")
    end
  end
end
