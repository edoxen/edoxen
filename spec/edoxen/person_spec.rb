# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::Person do
  it_behaves_like "extension host", factory: {}

  it "round-trips a full person record" do
    payload = {
      "name" => { "given" => "Jane", "family" => "Doe", "formatted" => "Jane Doe" },
      "role" => "chair",
      "affiliation" => "ACME",
      "contact_methods" => [
        { "kind" => "email", "value" => "jane@acme.org", "primary" => true },
        { "kind" => "phone", "value" => "+1-555-0100", "label" => "Office" }
      ],
      "identifiers" => [
        { "kind" => "orcid", "value" => "0000-0001-0002-0003" }
      ]
    }
    p = described_class.from_yaml(YAML.dump(payload))
    expect(p.name).to be_a(Edoxen::Name)
    expect(p.name.display).to eq("Jane Doe")
    expect(p.name.family).to eq("Doe")
    expect(p.role).to eq("chair")
    expect(p.contact_methods.first).to be_a(Edoxen::ContactMethod)
    expect(p.contact_methods.first.value).to eq("jane@acme.org")
    expect(p.identifiers.first).to be_a(Edoxen::ContactIdentifier)
    expect(p.identifiers.first.value).to eq("0000-0001-0002-0003")

    reload = described_class.from_yaml(p.to_yaml)
    expect(reload.contact_methods.first.value).to eq("jane@acme.org")
  end
end
