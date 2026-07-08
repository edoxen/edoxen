# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::SourceUrl do
  describe "round-trip serialization" do
    it "stores ref, format, spelling (ISO 24229)" do
      su = described_class.from_yaml(
        YAML.dump(
          "ref" => "https://example.com/file.pdf",
          "format" => "pdf",
          "spelling" => "eng"
        )
      )
      expect(su.ref).to eq("https://example.com/file.pdf")
      expect(su.format).to eq("pdf")
      expect(su.spelling).to eq("eng")
    end

    it "round-trips through YAML" do
      original = described_class.from_yaml(
        YAML.dump(
          "ref" => "https://example.com/file.pdf",
          "format" => "pdf",
          "spelling" => "eng"
        )
      )
      reload = described_class.from_yaml(original.to_yaml)
      expect(reload.ref).to eq("https://example.com/file.pdf")
      expect(reload.format).to eq("pdf")
      expect(reload.spelling).to eq("eng")
    end
  end
end
