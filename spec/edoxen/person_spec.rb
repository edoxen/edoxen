# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::Person do
  it_behaves_like "extension host", factory: {}

  it "round-trips a full person record" do
    payload = {
      "name" => "Jane Doe", "role" => "chair",
      "affiliation" => "ACME", "email" => "jane@acme.org",
      "phone" => "+1-555-0100", "orcid" => "0000-0001-0002-0003"
    }
    p = described_class.from_yaml(YAML.dump(payload))
    expect(p.name).to eq("Jane Doe")
    expect(p.role).to eq("chair")
    expect(p.orcid).to eq("0000-0001-0002-0003")

    reload = described_class.from_yaml(p.to_yaml)
    expect(reload.email).to eq("jane@acme.org")
  end
end
