# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::MinutesSection do
  it "round-trips a section with narrative markdown" do
    payload = {
      "number" => "5",
      "title" => [{ "spelling" => "eng", "value" => "Report by the CIML President" }],
      "narrative" => [{ "spelling" => "eng", "value" => "The President reported on the year's activities..." }],
      "page_start" => 12,
      "page_end" => 14
    }
    s = described_class.from_yaml(YAML.dump(payload))
    expect(s.number).to eq("5")
    expect(s.title.first.value).to eq("Report by the CIML President")
    expect(s.narrative.first.value).to match(/President reported/)
    expect(s.page_start).to eq(12)

    reload = described_class.from_yaml(s.to_yaml)
    expect(reload.number).to eq("5")
    expect(reload.narrative.first.value).to match(/President reported/)
  end

  it "carries optional references" do
    payload = {
      "number" => "10.1",
      "title" => [{ "spelling" => "eng", "value" => "2021 accounts" }],
      "references" => [{ "ref" => "OIML/2021/accounts", "kind" => "document" }]
    }
    s = described_class.from_yaml(YAML.dump(payload))
    expect(s.references.first).to be_a(Edoxen::Reference)
    expect(s.references.first.ref).to eq("OIML/2021/accounts")
  end
end

RSpec.describe Edoxen::Minutes do
  let(:payload) do
    {
      "identifier" => [{ "prefix" => "CIML", "number" => "57" }],
      "urn" => "urn:oiml:ciml:minutes:ciml-57-eng",
      "spelling" => "eng",
      "source_doc" => "https://example.org/ciml-57-minutes.pdf",
      "source_pages" => "1-56",
      "sections" => [
        { "number" => "1",
          "title" => [{ "spelling" => "eng", "value" => "Opening remarks" }],
          "narrative" => [{ "spelling" => "eng", "value" => "The President opened the meeting..." }] },
        { "number" => "10.1",
          "title" => [{ "spelling" => "eng", "value" => "2021 accounts" }],
          "narrative" => [{ "spelling" => "eng", "value" => "The 2021 accounts were approved." }] }
      ]
    }
  end

  it "round-trips a full minutes document" do
    m = described_class.from_yaml(YAML.dump(payload))
    expect(m.identifier.first).to be_a(Edoxen::StructuredIdentifier)
    expect(m.spelling).to eq("eng")
    expect(m.sections.size).to eq(2)
    expect(m.sections.first).to be_a(Edoxen::MinutesSection)
    expect(m.sections.first.title.first.value).to eq("Opening remarks")

    reload = described_class.from_yaml(m.to_yaml)
    expect(reload.sections.size).to eq(2)
    expect(reload.sections[1].number).to eq("10.1")
  end

  describe "#find_section" do
    let(:minutes) { described_class.from_yaml(YAML.dump(payload)) }

    it "finds a section by number" do
      match = minutes.find_section("10.1")
      expect(match).not_to be_nil
      expect(match.title.first.value).to eq("2021 accounts")
    end

    it "finds by integer number (coerced to_s)" do
      expect(minutes.find_section(1).title.first.value).to eq("Opening remarks")
    end

    it "returns nil when no section matches" do
      expect(minutes.find_section("99")).to be_nil
    end

    it "returns nil when called with nil" do
      expect(minutes.find_section(nil)).to be_nil
    end
  end
end
