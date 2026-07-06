# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::Voting do
  it_behaves_like "extension host", factory: {}

  describe "LUTAML VotingStatus / VotingMethod / VotingOutcome coverage" do
    it "round-trips status, method, result" do
      payload = {
        "identifier" => "voting-1",
        "status" => "decided",
        "voting_method" => "roll_call",
        "result" => "passed",
        "on_motion" => "urn:x:motion:1"
      }
      v = described_class.from_yaml(YAML.dump(payload))
      expect(v.status).to eq("decided")
      expect(v.voting_method).to eq("roll_call")
      expect(v.result).to eq("passed")
      expect(v.on_motion).to eq("urn:x:motion:1")
    end
  end

  it "carries counts, casting_vote, vote_records" do
    payload = {
      "counts" => { "ayes" => 5, "noes" => 3 },
      "casting_vote" => {
        "person" => { "name" => { "formatted" => "Chair" } },
        "vote" => "affirmative"
      },
      "vote_records" => [
        { "person" => { "name" => { "formatted" => "A" } }, "vote" => "affirmative" },
        { "person" => { "name" => { "formatted" => "B" } }, "vote" => "negative" }
      ]
    }
    v = described_class.from_yaml(YAML.dump(payload))
    expect(v.counts).to be_a(Edoxen::VotingCounts)
    expect(v.casting_vote).to be_a(Edoxen::VoteRecord)
    expect(v.vote_records).to all(be_a(Edoxen::VoteRecord))
    expect(v.vote_records.size).to eq(2)
  end

  describe "#decided? / #in_progress? / #passed? / #negatived? / #tied?" do
    it "decided? tracks status" do
      expect(described_class.new(status: "decided")).to be_decided
      expect(described_class.new(status: "called")).not_to be_decided
    end

    it "in_progress? tracks status" do
      expect(described_class.new(status: "in_progress")).to be_in_progress
    end

    it "passed? requires decided + passed" do
      expect(described_class.new(status: "decided", result: "passed")).to be_passed
      expect(described_class.new(status: "in_progress", result: "passed")).not_to be_passed
    end

    it "negatived? requires decided + negatived" do
      expect(described_class.new(status: "decided", result: "negatived")).to be_negatived
    end

    it "tied? requires decided + tied" do
      expect(described_class.new(status: "decided", result: "tied")).to be_tied
    end
  end
end
