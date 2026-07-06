# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::EntityRef do
  describe "identity (single of three)" do
    it "is valid with a URN" do
      ref = described_class.new(urn: "urn:x:decision:1")
      expect(ref).to be_valid
      expect(ref.resolved_identity).to eq("urn:x:decision:1")
    end

    it "is valid with a StructuredIdentifier" do
      ref = described_class.new(
        identifier: Edoxen::StructuredIdentifier.new(prefix: "ACME", number: "2026-001")
      )
      expect(ref).to be_valid
      expect(ref.resolved_identity).to be_a(Edoxen::StructuredIdentifier)
      expect(ref.to_s).to eq("ACME/2026-001")
    end

    it "is valid with a local_ref" do
      ref = described_class.new(local_ref: "agenda-item-4.2")
      expect(ref).to be_valid
      expect(ref.resolved_identity).to eq("agenda-item-4.2")
    end

    it "is invalid when no identity field is set" do
      expect(described_class.new).not_to be_valid
    end
  end

  describe "#resolved_identity precedence" do
    it "prefers URN over identifier" do
      ref = described_class.new(
        urn: "urn:x:1",
        identifier: Edoxen::StructuredIdentifier.new(prefix: "X", number: "1")
      )
      expect(ref.resolved_identity).to eq("urn:x:1")
    end

    it "prefers identifier over local_ref" do
      ref = described_class.new(
        identifier: Edoxen::StructuredIdentifier.new(prefix: "X", number: "1"),
        local_ref: "local-1"
      )
      expect(ref.resolved_identity).to be_an(Edoxen::StructuredIdentifier)
    end

    it "prefers URN over local_ref" do
      ref = described_class.new(urn: "urn:x:1", local_ref: "local-1")
      expect(ref.resolved_identity).to eq("urn:x:1")
    end

    it "returns nil when no identity is set" do
      expect(described_class.new.resolved_identity).to be_nil
    end
  end

  describe "XOR contract (TODO.update/13)" do
    # The wire contract is exactly-one-of (urn | identifier | local_ref).
    # Multiple identities on the same ref are ambiguous data — the
    # precedence rule above is a tiebreaker, not a feature.
    it "is invalid when no identity field is set" do
      expect(described_class.new).not_to be_valid
      expect(described_class.new).not_to be_multiple_identities
    end

    it "is valid when exactly one identity field is set" do
      expect(described_class.new(urn: "urn:x:1")).to be_valid
      expect(described_class.new(identifier: Edoxen::StructuredIdentifier.new(prefix: "X", number: "1"))).to be_valid
      expect(described_class.new(local_ref: "agenda-item-4.2")).to be_valid
    end

    it "is invalid when two identities are set" do
      ref = described_class.new(
        urn: "urn:x:1",
        identifier: Edoxen::StructuredIdentifier.new(prefix: "X", number: "1")
      )
      expect(ref).not_to be_valid
      expect(ref).to be_multiple_identities
    end

    it "is invalid when all three identities are set" do
      ref = described_class.new(
        urn: "urn:x:1",
        identifier: Edoxen::StructuredIdentifier.new(prefix: "X", number: "1"),
        local_ref: "local-1"
      )
      expect(ref).not_to be_valid
      expect(ref).to be_multiple_identities
    end

    it "treats an empty string identity as unset (still valid if another is set)" do
      ref = described_class.new(urn: "", local_ref: "agenda-item-4.2")
      expect(ref).to be_valid
      expect(ref.resolved_identity).to eq("agenda-item-4.2")
    end
  end

  describe "round-trip through YAML" do
    it "round-trips a URN-identified ref" do
      ref = described_class.from_yaml(YAML.dump(
                                        "urn" => "urn:acme:decision:1", "kind" => "resulting"
                                      ))
      expect(ref.urn).to eq("urn:acme:decision:1")
      reload = described_class.from_yaml(ref.to_yaml)
      expect(reload.urn).to eq("urn:acme:decision:1")
    end

    it "round-trips a StructuredIdentifier-identified ref" do
      ref = described_class.from_yaml(YAML.dump(
                                        "identifier" => { "prefix" => "ACME", "number" => "2026-001" }
                                      ))
      expect(ref.identifier).to be_a(Edoxen::StructuredIdentifier)
      expect(ref.to_s).to eq("ACME/2026-001")
    end
  end

  describe "Motion.resulting_decision_ref pilot (TODO 44)" do
    it "lets a Motion carry a typed EntityRef parallel to the bare String" do
      motion = Edoxen::Motion.from_yaml(YAML.dump(
                                          "identifier" => "motion-1",
                                          "status" => "carried",
                                          "resulting_decision" => "urn:x:decision:1",
                                          "resulting_decision_ref" => { "urn" => "urn:x:decision:1" }
                                        ))
      expect(motion.resulting_decision).to eq("urn:x:decision:1")
      expect(motion.resulting_decision_ref).to be_a(Edoxen::EntityRef)
      expect(motion.resulting_decision_ref.resolved_identity).to eq("urn:x:decision:1")
    end
  end

  describe "TODO 45 derivation accessors" do
    let(:meeting) do
      Edoxen::Meeting.new(
        urn: "urn:x:meeting:1",
        motions: [
          Edoxen::Motion.new(urn: "urn:x:motion:a", resulting_decision: "urn:x:decision:1"),
          Edoxen::Motion.new(urn: "urn:x:motion:b", resulting_decision: "urn:x:decision:2")
        ],
        votings: [
          Edoxen::Voting.new(on_motion: "urn:x:motion:a"),
          Edoxen::Voting.new(on_motion: "urn:x:motion:b")
        ]
      )
    end

    it "Motion#votings_in derives votings from the meeting" do
      motion = meeting.motions.first
      derived = motion.votings_in(meeting: meeting)
      expect(derived.size).to eq(1)
      expect(derived.first.on_motion).to eq("urn:x:motion:a")
    end

    it "Decision#brought_by_motions_in derives motions from the meeting" do
      decision = Edoxen::Decision.new(urn: "urn:x:decision:1")
      derived = decision.brought_by_motions_in(meeting: meeting)
      expect(derived.size).to eq(1)
      expect(derived.first.urn).to eq("urn:x:motion:a")
    end

    it "Topic#decisions_in derives decisions from the collection" do
      collection = Edoxen::DecisionCollection.new(
        decisions: [
          Edoxen::Decision.new(urn: "urn:x:decision:1", about_topics: ["urn:x:topic:t"]),
          Edoxen::Decision.new(urn: "urn:x:decision:2", about_topics: ["urn:x:topic:other"])
        ]
      )
      topic = Edoxen::Topic.new(urn: "urn:x:topic:t")
      derived = topic.decisions_in(collection: collection)
      expect(derived.size).to eq(1)
      expect(derived.first.urn).to eq("urn:x:decision:1")
    end
  end
end
