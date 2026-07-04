# frozen_string_literal: true

require "spec_helper"

# Shared coverage for every v2 entity that exposes the
# `extensions: MeetingExtension[0..*]` profile slot. Asserts the field
# round-trips through YAML, including a nested attributes list and a
# nested recursive extension — both load-bearing shapes for the
# profile mechanism (ISO 8601-2 §15).
#
# Per CLAUDE.md, no model class hand-rolls (de)serialization; the
# `extensions` attribute and its `MeetingExtension` collection type
# drive everything via lutaml-model. This shared example is the
# regression net for that invariant.
RSpec.shared_examples "extension host" do |factory:|
  let(:profile_payload) do
    {
      "extensions" => [
        {
          "profile" => "legco",
          "kind" => "vote_block",
          "ref" => "urn:legco:vote-block:1",
          "attributes" => [
            { "key" => "division", "value" => "yes" },
            { "key" => "vote_count", "value" => "37" }
          ]
        },
        {
          "profile" => "outer",
          "extensions" => [{ "profile" => "inner", "kind" => "x" }]
        }
      ]
    }
  end

  let(:subject_with_extensions) do
    described_class.from_yaml(YAML.dump(profile_payload.merge(factory)))
  end

  it "round-trips extensions[] through YAML" do
    entity = subject_with_extensions
    expect(entity.extensions).to be_an(Array)
    expect(entity.extensions.size).to eq(2)

    first = entity.extensions.first
    expect(first).to be_an(Edoxen::MeetingExtension)
    expect(first.profile).to eq("legco")
    expect(first.kind).to eq("vote_block")
    expect(first.ref).to eq("urn:legco:vote-block:1")
    expect(first.attributes).to all(be_an(Edoxen::ExtensionAttribute))
    expect(first.attributes.map(&:key)).to eq(%w[division vote_count])
  end

  it "supports nested extensions (recursive profile mechanism)" do
    entity = subject_with_extensions
    nested = entity.extensions[1].extensions.first
    expect(nested).to be_an(Edoxen::MeetingExtension)
    expect(nested.profile).to eq("inner")
  end

  it "round-trips extensions through to_yaml and back unchanged" do
    entity = subject_with_extensions
    reloaded = described_class.from_yaml(entity.to_yaml)
    expect(reloaded.extensions.size).to eq(entity.extensions.size)
    expect(reloaded.extensions.first.attributes.map(&:value))
      .to eq(%w[yes 37])
  end

  it "tolerates an empty extensions list" do
    entity = described_class.from_yaml(YAML.dump(factory.merge("extensions" => [])))
    expect(entity.extensions).to eq([])
  end
end
