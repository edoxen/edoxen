# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::ContactIdentifier do
  it_behaves_like "extension host", factory: {}

  describe "LUTAML ContactIdentifierKind coverage" do
    Edoxen::Enums::CONTACT_IDENTIFIER_KIND.each do |kind|
      it "round-trips kind=#{kind}" do
        ci = described_class.from_yaml(YAML.dump("kind" => kind, "value" => "x"))
        expect(ci.kind).to eq(kind)
      end
    end
  end

  it "round-trips value (e.g. an ORCID)" do
    payload = { "kind" => "orcid", "value" => "0000-0001-0002-0003" }
    ci = described_class.from_yaml(YAML.dump(payload))
    expect(ci.kind).to eq("orcid")
    expect(ci.value).to eq("0000-0001-0002-0003")

    reload = described_class.from_yaml(ci.to_yaml)
    expect(reload.value).to eq("0000-0001-0002-0003")
  end

  it "round-trips a ROR identifier" do
    payload = { "kind" => "ror", "value" => "04abc123" }
    ci = described_class.from_yaml(YAML.dump(payload))
    expect(ci.kind).to eq("ror")
    expect(ci.value).to eq("04abc123")
  end
end
