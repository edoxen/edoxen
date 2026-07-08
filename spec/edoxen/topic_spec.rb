# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::Topic do
  it_behaves_like "extension host", factory: {}

  it "carries all admin fields" do
    payload = {
      "identifier" => "topic-1",
      "urn" => "urn:x:topic:1",
      "title" => [{ "spelling" => "eng", "value" => "Q1 Budget" }],
      "description" => [{ "spelling" => "eng", "value" => "Review of Q1 budget" }],
      "status" => "decided",
      "resumption_of" => "urn:x:topic:prior"
    }
    t = described_class.from_yaml(YAML.dump(payload))
    expect(t.identifier).to eq("topic-1")
    expect(t.urn).to eq("urn:x:topic:1")
    expect(t.title.first.value).to eq("Q1 Budget")
    expect(t.status).to eq("decided")
    expect(t.resumption_of).to eq("urn:x:topic:prior")
  end

  it "carries documents, assets, references, motions, decisions" do
    payload = {
      "documents" => [{ "identifier" => "doc-1", "title" => [{ "spelling" => "eng", "value" => "T" }] }],
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
  it_behaves_like "extension host", factory: {}

  it "round-trips all fields" do
    payload = {
      "identifier" => "doc-1",
      "title" => [{ "spelling" => "eng", "value" => "Bill Text" }],
      "version" => "v2",
      "status" => "final",
      "url" => "https://example.com/bill.pdf",
      "format" => "pdf",
      "spelling" => "eng"
    }
    td = described_class.from_yaml(YAML.dump(payload))
    expect(td.identifier).to eq("doc-1")
    expect(td.title.first.value).to eq("Bill Text")
    expect(td.version).to eq("v2")
    expect(td.spelling).to eq("eng")
  end
end

RSpec.describe Edoxen::TopicAsset do
  it_behaves_like "extension host", factory: {}

  it "round-trips all fields" do
    payload = {
      "identifier" => "img-1",
      "title" => [{ "spelling" => "eng", "value" => "Map" }],
      "kind" => "image",
      "url" => "https://example.com/map.png",
      "format" => "png"
    }
    ta = described_class.from_yaml(YAML.dump(payload))
    expect(ta.identifier).to eq("img-1")
    expect(ta.kind).to eq("image")
  end
end
