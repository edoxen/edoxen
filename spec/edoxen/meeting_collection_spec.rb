# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::MeetingCollection do
  let(:fixture) { File.expand_path("../fixtures/meetings/multi-collection.yaml", __dir__) }

  it "loads a multi-meeting YAML" do
    c = described_class.from_yaml(File.read(fixture))
    expect(c.meetings.size).to eq(2)
    expect(c.meetings).to all(be_a(Edoxen::Meeting))
    expect(c.metadata.title).to eq("Sample meeting collection")
  end

  it "round-trips without data loss" do
    c = described_class.from_yaml(File.read(fixture))
    reload = described_class.from_yaml(c.to_yaml)
    expect(reload.meetings.size).to eq(c.meetings.size)
    expect(reload.meetings.map(&:urn)).to eq(c.meetings.map(&:urn))
  end

  describe "#find_by_urn" do
    it "returns the meeting with the matching URN" do
      c = described_class.from_yaml(File.read(fixture))
      match = c.find_by_urn("urn:oiml:ciml:meeting:ciml-56")
      expect(match).not_to be_nil
      expect(match.ordinal).to eq(56)
    end

    it "returns nil when no URN matches" do
      c = described_class.from_yaml(File.read(fixture))
      expect(c.find_by_urn("urn:does:not:exist")).to be_nil
    end
  end

  describe "#find_by_identifier" do
    it "matches by prefix + number" do
      c = described_class.from_yaml(File.read(fixture))
      match = c.find_by_identifier(prefix: "CIML", number: "55")
      expect(match).not_to be_nil
      expect(match.ordinal).to eq(55)
    end

    it "returns nil when no identifier matches" do
      c = described_class.from_yaml(File.read(fixture))
      expect(c.find_by_identifier(prefix: "CIML", number: "99")).to be_nil
    end
  end
end
