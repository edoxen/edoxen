# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::Approval do
  describe "LUTAML ApprovalType + ApprovalDegree coverage" do
    Edoxen::Enums::APPROVAL_TYPE.each do |approval_type|
      Edoxen::Enums::APPROVAL_DEGREE.each do |approval_degree|
        it "round-trips type=#{approval_type} degree=#{approval_degree}" do
          payload = {
            "type" => approval_type, "degree" => approval_degree,
            "date" => { "date" => "2024-01-15", "type" => "adoption" },
            "message" => "vote #{approval_type} at #{approval_degree}"
          }
          a = described_class.from_yaml(YAML.dump(payload))
          expect(a.type).to eq(approval_type)
          expect(a.degree).to eq(approval_degree)
          expect(a.date).to be_a(Edoxen::DecisionDate)
          expect(a.message).to eq("vote #{approval_type} at #{approval_degree}")

          reload = described_class.from_yaml(a.to_yaml)
          expect(reload.type).to eq(approval_type)
          expect(reload.degree).to eq(approval_degree)
        end
      end
    end
  end
end
