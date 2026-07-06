# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::VoteRecord do
  it_behaves_like "extension host", factory: { "person" => { "name" => { "formatted" => "Jane" } }, "vote" => "affirmative" }

  describe "LUTAML VoteType coverage" do
    Edoxen::Enums::VOTE_TYPE.each do |vote|
      it "round-trips vote=#{vote}" do
        payload = {
          "decision_ref" => "urn:example:decision:1",
          "person" => { "name" => { "formatted" => "Jane" } },
          "vote" => vote
        }
        v = described_class.from_yaml(YAML.dump(payload))
        expect(v.vote).to eq(vote)
        expect(v.decision_ref).to eq("urn:example:decision:1")
      end
    end
  end

  it "carries an affiliation and notes" do
    payload = {
      "decision_ref" => "urn:example:decision:1",
      "person" => { "name" => { "formatted" => "Jane" } },
      "affiliation" => "NB of France",
      "vote" => "affirmative",
      "notes" => "Endorsed"
    }
    v = described_class.from_yaml(YAML.dump(payload))
    expect(v.affiliation).to eq("NB of France")
    expect(v.notes).to eq("Endorsed")
  end
end
