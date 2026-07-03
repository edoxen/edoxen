# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::Topic do
  it "carries all admin fields" do
    payload = {
      "identifier" => "topic-1",
      "urn" => "urn:x:topic:1",
      "title" => "Q1 Budget",
      "description" => "Review of Q1 budget",
      "status" => "decided",
      "resumption_of" => "urn:x:topic:prior"
    }
    t = described_class.from_yaml(YAML.dump(payload))
    expect(t.identifier).to eq("topic-1")
    expect(t.urn).to eq("urn:x:topic:1")
    expect(t.title).to eq("Q1 Budget")
    expect(t.status).to eq("decided")
    expect(t.resumption_of).to eq("urn:x:topic:prior")
  end

  it "carries documents, assets, references, motions, decisions" do
    payload = {
      "documents" => [{ "identifier" => "doc-1", "title" => "T" }],
      "assets" => [{ "identifier" => "img-1", "kind" => "image" }],
      "references" => [{ "ref" => "ISO 9735", "kind" => "standard" }],
      "motions" => ["urn:x:motion:1"],
      "decisions" => ["urn:x:decision:1"]
    }
    t = described_class.from_yaml(YAML.dump(payload))
    expect(t.documents.first).to be_a(Edoxen::TopicDocument)
    expect(t.assets.first).to be_a(Edoxen::TopicAsset)
    expect(t.references.first).to be_a(Edoxen::Reference)
    expect(t.motions).to eq(["urn:x:motion:1"])
    expect(t.decisions).to eq(["urn:x:decision:1"])
  end
end

RSpec.describe Edoxen::TopicDocument do
  it "round-trips all fields" do
    payload = {
      "identifier" => "doc-1",
      "title" => "Bill Text",
      "version" => "v2",
      "status" => "final",
      "url" => "https://example.com/bill.pdf",
      "format" => "pdf",
      "language_code" => "eng"
    }
    td = described_class.from_yaml(YAML.dump(payload))
    expect(td.identifier).to eq("doc-1")
    expect(td.title).to eq("Bill Text")
    expect(td.version).to eq("v2")
    expect(td.language_code).to eq("eng")
  end
end

RSpec.describe Edoxen::TopicAsset do
  it "round-trips all fields" do
    payload = {
      "identifier" => "img-1",
      "title" => "Map",
      "kind" => "image",
      "url" => "https://example.com/map.png",
      "format" => "png"
    }
    ta = described_class.from_yaml(YAML.dump(payload))
    expect(ta.identifier).to eq("img-1")
    expect(ta.kind).to eq("image")
  end
end
