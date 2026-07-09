# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::DecisionCollection do
  describe "real-world fixtures" do
    Dir.glob(File.expand_path("../fixtures/*.yaml", __dir__)).each do |fixture|
      it "loads #{File.basename(fixture)}" do
        collection = described_class.from_yaml(File.read(fixture))
        expect(collection).to be_a(described_class)
        expect(collection.decisions).to all(be_a(Edoxen::Decision))
        expect(collection.decisions).not_to be_empty
      end

      it "round-trips #{File.basename(fixture)}" do
        original = described_class.from_yaml(File.read(fixture))
        reloaded = described_class.from_yaml(original.to_yaml)
        expect(reloaded.decisions.size).to eq(original.decisions.size)
        expect(reloaded.metadata).to eq(original.metadata)
      end
    end
  end

  describe "empty / partial inputs" do
    it "is constructible with only metadata" do
      c = described_class.new(metadata: Edoxen::DecisionMetadata.new(title: [Edoxen::LocalizedString.new(
        spelling: "eng", value: "X"
      )]))
      expect(c.decisions).to be_nil
      expect(c.metadata.title.first.value).to eq("X")
    end

    it "is constructible with an empty decisions array" do
      c = described_class.new(decisions: [])
      expect(c.decisions).to eq([])
    end
  end
end
