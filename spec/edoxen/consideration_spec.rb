# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::Consideration do
  describe "LUTAML ConsiderationType coverage" do
    Edoxen::Enums::CONSIDERATION_TYPE.each do |verb|
      it "round-trips a consideration of type=#{verb}" do
        payload = {
          "type" => verb,
          "date_effective" => { "date" => "2024-01-15", "type" => "adoption" },
          "message" => [{ "spelling" => "eng", "value" => "#{verb} the prior decision" }]
        }
        c = described_class.from_yaml(YAML.dump(payload))
        expect(c.type).to eq(verb)
        expect(c.date_effective).to be_a(Edoxen::DecisionDate)
        expect(c.message.first).to be_a(Edoxen::LocalizedString)
        expect(c.message.first.value).to eq("#{verb} the prior decision")

        reload = described_class.from_yaml(c.to_yaml)
        expect(reload.type).to eq(verb)
      end
    end
  end
end
