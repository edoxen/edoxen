# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::MeetingExtension do
  it "round-trips profile, kind, ref" do
    payload = {
      "profile" => "legco",
      "kind" => "vote_block",
      "ref" => "urn:legco:vote-block:1"
    }
    ext = described_class.from_yaml(YAML.dump(payload))
    expect(ext.profile).to eq("legco")
    expect(ext.kind).to eq("vote_block")
    expect(ext.ref).to eq("urn:legco:vote-block:1")
  end

  it "carries attributes as ExtensionAttribute list" do
    payload = {
      "profile" => "ietf",
      "attributes" => [
        { "key" => "wg_name", "value" => "quic" },
        { "key" => "draft_name", "value" => "draft-ietf-quic-v2" }
      ]
    }
    ext = described_class.from_yaml(YAML.dump(payload))
    expect(ext.attributes).to all(be_a(Edoxen::ExtensionAttribute))
    expect(ext.attributes.map(&:key)).to eq(%w[wg_name draft_name])
  end

  it "supports nested extensions (recursive profile mechanism)" do
    payload = {
      "profile" => "outer",
      "extensions" => [{ "profile" => "inner", "kind" => "x" }]
    }
    ext = described_class.from_yaml(YAML.dump(payload))
    expect(ext.extensions.first).to be_a(described_class)
    expect(ext.extensions.first.profile).to eq("inner")
  end
end

RSpec.describe Edoxen::ExtensionAttribute do
  it "round-trips key + value" do
    ea = described_class.from_yaml(YAML.dump("key" => "k", "value" => "v"))
    expect(ea.key).to eq("k")
    expect(ea.value).to eq("v")
  end
end
