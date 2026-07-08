# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::Action do
  let(:fixture_yaml) do
    <<~YAML
      ---
      type: resolves
      date_effective:
        date: 2024-01-15
        type: adoption
      message:
        - spelling: eng
          value: resolves to implement the new standard
    YAML
  end

  describe "LUTAML ActionType coverage" do
    Edoxen::Enums::ACTION_TYPE.each do |verb|
      it "round-trips an action of type=#{verb}" do
        payload = {
          "type" => verb,
          "date_effective" => {
            "date" => "2024-01-15", "type" => "adoption"
          },
          "message" => [{ "spelling" => "eng", "value" => "#{verb} the proposal" }]
        }
        a = described_class.from_yaml(YAML.dump(payload))
        expect(a.type).to eq(verb)
        expect(a.date_effective).to be_a(Edoxen::DecisionDate)
        expect(a.date_effective.date).to eq(Date.new(2024, 1, 15))
        expect(a.message.first).to be_a(Edoxen::LocalizedString)
        expect(a.message.first.value).to eq("#{verb} the proposal")

        reload = described_class.from_yaml(a.to_yaml)
        expect(reload.type).to eq(verb)
        expect(reload.message.first.value).to eq("#{verb} the proposal")
      end
    end
  end

  describe "round-trip through the existing fixture" do
    it "re-serializes consistently" do
      original = described_class.from_yaml(fixture_yaml)
      reloaded = described_class.from_yaml(original.to_yaml)
      expect(reloaded.type).to eq("resolves")
      expect(reloaded.message.first.value).to eq("resolves to implement the new standard")
      expect(reloaded.date_effective.date).to eq(Date.new(2024, 1, 15))
      expect(reloaded.date_effective.type).to eq("adoption")
    end
  end

  describe "Action-specific absence of `degree`" do
    it "rejects `degree` in the action shape (via from_yaml → to_hash)" do
      payload = YAML.dump(
        "type" => "approves", "date_effective" => { "date" => "2024-01-15", "type" => "adoption" },
        "message" => [{ "spelling" => "eng", "value" => "approves the plan" }],
        "degree" => "unanimous"
      )
      a = described_class.from_yaml(payload)
      expect(a.to_hash).not_to have_key("degree")
    end
  end
end
