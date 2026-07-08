# frozen_string_literal: true

require "spec_helper"

# MECE parity spec for the 1.0 (TODO.refactor/1.0-design) bidirectional
# relationships. Through v2.x, each pair is stored on one side and
# derived on the other. This spec guards the 1.0 removal of the
# stored side: if the derived lookup ever disagrees with the stored
# side (given the SSOT direction documented in Decision/Motion/Topic),
# this spec catches it.
#
# Per TODO.refactor/1.0-design: the derived side wins for queries. The stored
# side is the SSOT for writes (in v2.x).

RSpec.describe "MECE parity (1.0 TODO.refactor/1.0-design)" do
  describe "Motion → Decision (storage SSOT: Motion.resulting_decision[_ref])" do
    let(:meeting) do
      Edoxen::Meeting.new(
        urn: "urn:x:meeting:1",
        motions: [
          Edoxen::Motion.new(urn: "urn:x:motion:a", resulting_decision: "urn:x:decision:1"),
          Edoxen::Motion.new(
            urn: "urn:x:motion:b",
            resulting_decision_ref: Edoxen::EntityRef.new(urn: "urn:x:decision:2")
          )
        ]
      )
    end

    it "Decision#brought_by_motions_in finds motions whose resulting_decision matches" do
      d1 = Edoxen::Decision.new(urn: "urn:x:decision:1")
      d2 = Edoxen::Decision.new(urn: "urn:x:decision:2")
      d3 = Edoxen::Decision.new(urn: "urn:x:decision:999")

      expect(d1.brought_by_motions_in(meeting: meeting).map(&:urn)).to eq(["urn:x:motion:a"])
      expect(d2.brought_by_motions_in(meeting: meeting).map(&:urn)).to eq(["urn:x:motion:b"])
      expect(d3.brought_by_motions_in(meeting: meeting)).to be_empty
    end

    it "the derived lookup agrees with the stored form for both shapes (String + EntityRef)" do
      # Both stored shapes — `Motion#resulting_decision` (String) and
      # `Motion#resulting_decision_ref` (EntityRef) — must resolve
      # through the same derived accessor.
      motion_strings = meeting.motions.select(&:resulting_decision)
      motion_refs = meeting.motions.select(&:resulting_decision_ref)
      expect(motion_strings.size).to eq(1)
      expect(motion_refs.size).to eq(1)

      d1 = Edoxen::Decision.new(urn: "urn:x:decision:1")
      d2 = Edoxen::Decision.new(urn: "urn:x:decision:2")
      expect(d1.brought_by_motions_in(meeting: meeting).first.urn).to eq(motion_strings.first.urn)
      expect(d2.brought_by_motions_in(meeting: meeting).first.urn).to eq(motion_refs.first.urn)
    end
  end

  describe "Decision → Component (storage SSOT: Decision.made_in_component)" do
    let(:meeting) do
      Edoxen::Meeting.new(
        components: [
          Edoxen::MeetingComponent.new(identifier: "comp-1", urn: "urn:x:component:1"),
          Edoxen::MeetingComponent.new(identifier: "comp-2", urn: "urn:x:component:2")
        ]
      )
    end

    it "Decision#component_in resolves via identifier OR urn" do
      by_identifier = Edoxen::Decision.new(made_in_component: "comp-1")
      by_urn = Edoxen::Decision.new(made_in_component: "urn:x:component:2")
      by_missing = Edoxen::Decision.new(made_in_component: "no-such")

      expect(by_identifier.component_in(meeting: meeting).identifier).to eq("comp-1")
      expect(by_urn.component_in(meeting: meeting).urn).to eq("urn:x:component:2")
      expect(by_missing.component_in(meeting: meeting)).to be_nil
    end
  end

  describe "Decision → Topic (storage SSOT: Decision.about_topics)" do
    let(:collection) do
      Edoxen::DecisionCollection.new(
        decisions: [
          Edoxen::Decision.new(urn: "urn:x:decision:1", about_topics: ["urn:x:topic:a", "urn:x:topic:b"]),
          Edoxen::Decision.new(urn: "urn:x:decision:2", about_topics: ["urn:x:topic:a"])
        ]
      )
    end

    it "Topic#decisions_in derives from Decision.about_topics" do
      a = Edoxen::Topic.new(urn: "urn:x:topic:a")
      b = Edoxen::Topic.new(urn: "urn:x:topic:b")
      c = Edoxen::Topic.new(urn: "urn:x:topic:c")

      expect(a.decisions_in(collection: collection).map(&:urn).sort).to eq(["urn:x:decision:1", "urn:x:decision:2"])
      expect(b.decisions_in(collection: collection).map(&:urn)).to eq(["urn:x:decision:1"])
      expect(c.decisions_in(collection: collection)).to be_empty
    end
  end

  describe "Motion → Voting (storage SSOT: Voting.on_motion)" do
    let(:meeting) do
      Edoxen::Meeting.new(
        motions: [
          Edoxen::Motion.new(urn: "urn:x:motion:a"),
          Edoxen::Motion.new(urn: "urn:x:motion:b")
        ],
        votings: [
          Edoxen::Voting.new(on_motion: "urn:x:motion:a"),
          Edoxen::Voting.new(on_motion: "urn:x:motion:a"),
          Edoxen::Voting.new(on_motion: "urn:x:motion:b")
        ]
      )
    end

    it "Motion#votings_in derives votings from Voting.on_motion" do
      a = meeting.motions.first
      b = meeting.motions.last

      expect(a.votings_in(meeting: meeting).size).to eq(2)
      expect(b.votings_in(meeting: meeting).size).to eq(1)
    end
  end
end
