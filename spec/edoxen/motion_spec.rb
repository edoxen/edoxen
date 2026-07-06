# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::Motion do
  it_behaves_like "extension host", factory: {}

  describe "LUTAML MotionStatus coverage" do
    Edoxen::Enums::MOTION_STATUS.each do |s|
      it "round-trips status=#{s}" do
        m = described_class.from_yaml(YAML.dump("status" => s))
        expect(m.status).to eq(s)
      end
    end
  end

  it "carries identifier, urn, text, mover, seconders, introduced_at" do
    payload = {
      "identifier" => "motion-1",
      "urn" => "urn:x:motion:1",
      "text" => "I move that we adjourn",
      "mover" => { "name" => { "formatted" => "Jane" } },
      "seconders" => [{ "name" => { "formatted" => "Sara" } }, { "name" => { "formatted" => "Bob" } }],
      "status" => "seconded",
      "introduced_at" => "2026-03-15T10:30:00Z"
    }
    m = described_class.from_yaml(YAML.dump(payload))
    expect(m.identifier).to eq("motion-1")
    expect(m.urn).to eq("urn:x:motion:1")
    expect(m.text).to eq("I move that we adjourn")
    expect(m.mover).to be_a(Edoxen::Person)
    expect(m.seconders).to all(be_a(Edoxen::Person))
    expect(m.seconders.size).to eq(2)
    expect(m.status).to eq("seconded")
  end

  describe "#carried?" do
    it "returns true when status == carried" do
      expect(described_class.new(status: "carried")).to be_carried
    end

    it "returns false otherwise" do
      expect(described_class.new(status: "introduced")).not_to be_carried
    end
  end

  describe "#pending?" do
    %w[introduced seconded debating question_put voting].each do |s|
      it "returns true when status=#{s}" do
        expect(described_class.new(status: s)).to be_pending
      end
    end

    it "returns false once terminal" do
      expect(described_class.new(status: "carried")).not_to be_pending
    end

    it "returns false when status is nil" do
      expect(described_class.new).not_to be_pending
    end

    # MECE coverage: MOTION_STATUS partitions cleanly into terminal and
    # non-terminal. Catches a future enum addition that forgets to update
    # MOTION_TERMINAL.
    it "MOTION_TERMINAL ⊆ MOTION_STATUS, both non-empty" do
      terminal = Edoxen::Enums::MOTION_TERMINAL
      status = Edoxen::Enums::MOTION_STATUS
      extras = terminal - status
      expect(extras).to be_empty,
                        "MOTION_TERMINAL must be a subset of MOTION_STATUS (extras: #{extras})"
      expect(terminal).not_to be_empty
      expect(status - terminal).not_to be_empty
    end
  end
end
