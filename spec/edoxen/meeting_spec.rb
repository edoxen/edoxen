# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::Meeting do
  it_behaves_like "extension host", factory: { "identifier" => [{ "prefix" => "X", "number" => "1" }] }

  describe "LUTAML MeetingType coverage" do
    Edoxen::Enums::MEETING_TYPE.each do |t|
      it "round-trips type=#{t}" do
        m = described_class.from_yaml(YAML.dump(
                                        "identifier" => [{ "prefix" => "X", "number" => "1" }],
                                        "type" => t
                                      ))
        expect(m.type).to eq(t)
      end
    end
  end

  describe "LUTAML MeetingStatus coverage" do
    Edoxen::Enums::MEETING_STATUS.each do |s|
      it "round-trips status=#{s}" do
        m = described_class.from_yaml(YAML.dump(
                                        "identifier" => [{ "prefix" => "X", "number" => "1" }],
                                        "type" => "plenary", "status" => s
                                      ))
        expect(m.status).to eq(s)
      end
    end
  end

  it "carries all admin fields with their real types" do
    m = described_class.from_yaml(YAML.dump(
                                    "identifier" => [{ "prefix" => "CIML", "number" => "56" }],
                                    "urn" => "urn:oiml:ciml:meeting:ciml-56",
                                    "ordinal" => 56, "type" => "plenary",
                                    "date_range" => { "start" => "2021-10-18", "end" => "2021-10-22" },
                                    "venues" => [{ "kind" => "physical", "name" => "OIML HQ",
                                                   "lat" => 48.87, "lon" => 2.34 }],
                                    "officers" => [{ "role" => "chair", "person" => { "name" => "Roman Schwartz" } }],
                                    "agenda" => {
                                      "status" => "final",
                                      "items" => [{ "label" => "1", "kind" => "opening" }]
                                    },
                                    "deadlines" => [{ "date" => "2021-09-30", "description" => "Reg" }],
                                    "localizations" => [{ "language_code" => "eng", "title" => "56th" }]
                                  ))
    expect(m.identifier.first).to be_a(Edoxen::StructuredIdentifier)
    expect(m.date_range).to be_a(Edoxen::DateRange)
    expect(m.date_range.start).to eq(Date.new(2021, 10, 18))
    expect(m.venues.first).to be_a(Edoxen::Venue)
    expect(m.officers.first).to be_a(Edoxen::Officer)
    expect(m.chair.name).to eq("Roman Schwartz")
    expect(m.agenda).to be_a(Edoxen::Agenda)
    expect(m.deadlines.first).to be_a(Edoxen::Deadline)
    expect(m.localizations.first).to be_a(Edoxen::MeetingLocalization)
  end

  describe "real-world fixtures round-trip" do
    Dir.glob(File.expand_path("../fixtures/meetings/*.yaml", __dir__)).each do |f|
      next if File.basename(f) == "multi-collection.yaml"

      it "round-trips #{File.basename(f)} as a Meeting" do
        m = described_class.from_yaml(File.read(f))
        reload = described_class.from_yaml(m.to_yaml)
        expect(reload.identifier).to eq(m.identifier)
        expect(reload.type).to eq(m.type)
        expect(reload.localizations.size).to eq(m.localizations.size)
      end
    end
  end
end
