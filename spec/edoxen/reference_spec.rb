# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::Reference do
  it "round-trips a document reference" do
    payload = { "ref" => "ISO 9735-11", "kind" => "standard", "title" => [{ "spelling" => "eng", "value" => "EDIFACT" }] }
    r = described_class.from_yaml(YAML.dump(payload))
    expect(r.ref).to eq("ISO 9735-11")
    expect(r.kind).to eq("standard")
  end
end
