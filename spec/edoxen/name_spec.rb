# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::Name do
  it_behaves_like "extension host", factory: {}

  it "round-trips all structured + formatted fields" do
    payload = {
      "formatted" => "Dr Jane Q. Doe PhD",
      "family" => "Doe",
      "given" => "Jane",
      "additional" => "Quincy",
      "prefix" => "Dr",
      "suffix" => "PhD"
    }
    n = described_class.from_yaml(YAML.dump(payload))
    expect(n.formatted).to eq("Dr Jane Q. Doe PhD")
    expect(n.family).to eq("Doe")
    expect(n.given).to eq("Jane")
    expect(n.additional).to eq("Quincy")
    expect(n.prefix).to eq("Dr")
    expect(n.suffix).to eq("PhD")
  end

  describe "#display" do
    it "returns formatted when set" do
      n = described_class.new(formatted: "Jane Doe")
      expect(n.display).to eq("Jane Doe")
    end

    it "builds from structured components when formatted is nil" do
      n = described_class.new(prefix: "Dr", given: "Jane", additional: "Q",
                              family: "Doe", suffix: "PhD")
      expect(n.display).to eq("Dr Jane Q Doe PhD")
    end

    it "skips empty components" do
      n = described_class.new(given: "Jane", family: "Doe")
      expect(n.display).to eq("Jane Doe")
    end

    it "returns empty string when no fields are set" do
      expect(described_class.new.display).to eq("")
    end

    it "treats nil and empty-string components the same (single-pass reject)" do
      a = described_class.new(given: "Jane", family: nil)
      b = described_class.new(given: "Jane", family: "")
      expect(a.display).to eq("Jane")
      expect(b.display).to eq("Jane")
    end
  end
end
