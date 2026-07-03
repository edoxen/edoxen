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
      message: resolves to implement the new standard
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
          "message" => "#{verb} the proposal"
        }
        a = described_class.from_yaml(YAML.dump(payload))
        expect(a.type).to eq(verb)
        expect(a.date_effective).to be_a(Edoxen::DecisionDate)
        expect(a.date_effective.date).to eq(Date.new(2024, 1, 15))
        expect(a.message).to eq("#{verb} the proposal")

        reload = described_class.from_yaml(a.to_yaml)
        expect(reload.type).to eq(verb)
        expect(reload.message).to eq("#{verb} the proposal")
      end
    end
  end

  describe "round-trip through the existing fixture" do
    it "re-serializes consistently" do
      original = described_class.from_yaml(fixture_yaml)
      reloaded = described_class.from_yaml(original.to_yaml)
      expect(reloaded.type).to eq("resolves")
      expect(reloaded.message).to eq("resolves to implement the new standard")
      expect(reloaded.date_effective.date).to eq(Date.new(2024, 1, 15))
      expect(reloaded.date_effective.type).to eq("adoption")
    end
  end

  describe "Action-specific absence of `degree`" do
    # LUTAML canonical Action has no `degree` — degree lives on Approval only.
    it "rejects `degree` in the action shape (via from_yaml → to_hash)" do
      payload = YAML.dump(
        "type" => "approves", "date_effective" => { "date" => "2024-01-15", "type" => "adoption" },
        "message" => "approves the plan", "degree" => "unanimous"
      )
      a = described_class.from_yaml(payload)
      # lutaml-model ignores unknown fields silently, but the schema is the
      # strict source. Document the model behaviour here so a future change
      # is deliberate.
      expect(a.to_hash).not_to have_key("degree")
    end
  end
end
