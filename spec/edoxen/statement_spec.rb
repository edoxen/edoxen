# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::Statement do
  it_behaves_like "extension host", factory: {}

  describe "kind discriminator" do
    Edoxen::Enums::STATEMENT_KIND.each do |kind|
      it "accepts kind=#{kind}" do
        s = described_class.new(kind: kind)
        expect(s.kind).to eq(kind)
      end
    end

    it "does not enforce kind at construction time (lutaml-model is permissive)" do
      # The `values:` constraint is enforced at serialization time, not
      # at .new time. Construction accepts any string; the schema is
      # the strict source.
      s = described_class.new(kind: "not-a-statement-kind")
      expect(s.kind).to eq("not-a-statement-kind")
    end
  end

  it "round-trips a bilingual statement via from_yaml / to_yaml" do
    payload = {
      "kind" => "standpoint",
      "description" => [
        { "spelling" => "eng", "value" => "We oppose the proposal." },
        { "spelling" => "fra", "value" => "Nous nous opposons à la proposition." }
      ],
      "party" => [
        { "kind" => "person",
          "name" => [{ "spelling" => "eng",
                       "value" => { "formatted" => "Jane Doe" } }] }
      ]
    }
    s = described_class.from_yaml(YAML.dump(payload))

    expect(s.kind).to eq("standpoint")
    expect(s.description.size).to eq(2)
    expect(s.description.find { |l| l.spelling == "eng" }.value).to eq("We oppose the proposal.")
    expect(s.description.find { |l| l.spelling == "fra" }.value).to eq("Nous nous opposons à la proposition.")
    expect(s.party.first).to be_an(Edoxen::Person)
    expect(s.party.first.name.first.value.formatted).to eq("Jane Doe")

    reloaded = described_class.from_yaml(s.to_yaml)
    expect(reloaded.description.map(&:value).sort).to eq(s.description.map(&:value).sort)
  end

  it "carries an extensions[] slot" do
    payload = {
      "kind" => "comment",
      "description" => [{ "spelling" => "eng", "value" => "A note." }],
      "extensions" => [
        { "profile" => "ietf", "kind" => "note_meta",
          "attributes" => [{ "key" => "draft", "type" => "string", "value" => "draft-ietf-quic-v2" }] }
      ]
    }
    s = described_class.from_yaml(YAML.dump(payload))
    expect(s.extensions.first.profile).to eq("ietf")
    expect(s.extensions.first.attributes.first.typed_value).to eq("draft-ietf-quic-v2")
  end
end
