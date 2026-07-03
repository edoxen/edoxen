# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::DecisionDate do
  let(:fixture_yaml) do
    <<~YAML
      ---
      date: 2022-06-23
      type: adoption
    YAML
  end

  describe "enum validation (LUTAML-canonical DecisionDateType)" do
    Edoxen::Enums::DECISION_DATE_TYPE.each do |kind|
      it "accepts type=#{kind}" do
        rd = described_class.from_yaml(YAML.dump(
                                         "date" => "2024-01-15", "type" => kind
                                       ))
        expect(rd.type).to eq(kind)
      end
    end

    it "preserves non-enum type strings (lutaml-model is permissive at write time)" do
      rd = described_class.from_yaml(YAML.dump(
                                       "date" => "2024-01-15", "type" => "funky-new-date-type"
                                     ))
      expect(rd.type).to eq("funky-new-date-type")
    end
  end

  describe "round-trip serialization" do
    it "parses both fields" do
      rd = described_class.from_yaml(fixture_yaml)
      expect(rd.date).to eq(Date.new(2022, 6, 23))
      expect(rd.type).to eq("adoption")
    end

    it "round-trips without loss" do
      rd = described_class.from_yaml(fixture_yaml)
      reloaded = described_class.from_yaml(rd.to_yaml)
      expect(reloaded.date).to eq(Date.new(2022, 6, 23))
      expect(reloaded.type).to eq("adoption")
    end
  end
end
