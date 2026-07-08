# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::MeetingSeries do
  it_behaves_like "extension host", factory: {}

  it "round-trips series admin + recurrence + members" do
    payload = {
      "identifier" => [{ "prefix" => "ISO/TC154", "number" => "PlenarySeries" }],
      "urn" => "urn:iso:tc154:series:plenary",
      "name" => [{ "spelling" => "eng", "value" => "ISO/TC 154 Plenary Series" }],
      "recurrence" => { "freq" => "yearly", "interval" => 1 },
      "term" => "2024-2026",
      "contact" => { "name" => [{ "spelling" => "eng", "value" => { "formatted" => "ISO" } }], "role" => "organizer" },
      "meeting_refs" => ["urn:iso:tc154:meeting:41", "urn:iso:tc154:meeting:42"]
    }
    s = described_class.from_yaml(YAML.dump(payload))
    expect(s.identifier.first).to be_a(Edoxen::StructuredIdentifier)
    expect(s.urn).to eq("urn:iso:tc154:series:plenary")
    expect(s.recurrence).to be_a(Edoxen::Recurrence)
    expect(s.recurrence.freq).to eq("yearly")
    expect(s.term).to eq("2024-2026")
    expect(s.contact).to be_a(Edoxen::Contact)
    expect(s.meeting_refs).to eq(["urn:iso:tc154:meeting:41", "urn:iso:tc154:meeting:42"])
  end
end
