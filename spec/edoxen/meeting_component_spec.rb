# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::MeetingComponent do
  it_behaves_like "extension host", factory: {}

  it "round-trips all fields" do
    payload = {
      "identifier" => "comp-1",
      "kind" => "session",
      "title" => [{ "spelling" => "eng", "value" => "Morning Session" }],
      "starts_at" => "2026-03-15T09:00:00Z",
      "ends_at" => "2026-03-15T12:00:00Z",
      "venue_refs" => ["urn:x:venue:1"],
      "officers" => [{ "role" => "chair", "person" => { "name" => [{ "spelling" => "eng", "value" => { "formatted" => "Jane" } }] } }],
      "agenda_ref" => "urn:x:agenda:1",
      "minutes_ref" => "urn:x:minutes:1",
      "attendance_refs" => ["urn:x:attendance:1"]
    }
    c = described_class.from_yaml(YAML.dump(payload))
    expect(c.identifier).to eq("comp-1")
    expect(c.kind).to eq("session")
    expect(c.title.first.value).to eq("Morning Session")
    expect(c.officers.first).to be_a(Edoxen::Officer)
    expect(c.chair).to be_a(Edoxen::Person)
    expect(c.chair.name.first.value.display).to eq("Jane")
    expect(c.venue_refs).to eq(["urn:x:venue:1"])
  end

  describe "#duration_seconds" do
    it "returns the seconds between starts_at and ends_at" do
      c = described_class.new(
        starts_at: Time.parse("2026-03-15T09:00:00Z"),
        ends_at: Time.parse("2026-03-15T12:00:00Z")
      )
      expect(c.duration_seconds).to eq(3 * 60 * 60)
    end

    it "returns nil when either is missing" do
      expect(described_class.new.duration_seconds).to be_nil
    end
  end
end
