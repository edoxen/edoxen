# frozen_string_literal: true

require "spec_helper"

# Shared coverage for every v2 entity that exposes the
# `extensions: MeetingExtension[0..*]` profile slot. Asserts the field
# round-trips through YAML, including a typed ExtensionAttribute list
# — the load-bearing shape for the profile mechanism (ISO 8601-2 §15)
# after the v2.1 tightening (TODO.refactor/47).
#
# Per CLAUDE.md, no model class hand-rolls (de)serialization; the
# `extensions` attribute and its `MeetingExtension` collection type
# drive everything via lutaml-model. This shared example is the
# regression net for that invariant.
#
# v2.1 changes (TODO.refactor/47):
#   - MeetingExtension no longer recurses (`extensions[]` removed).
#   - ExtensionAttribute is typed (string/integer/float/boolean/date/
#     date_time) with a `type` discriminator.
#   - Backwards compat: bare `value: String` on the wire still parses
#     and is exposed via `string_value`.
RSpec.shared_examples "extension host" do |factory:|
  let(:profile_payload) do
    {
      "extensions" => [
        {
          "profile" => "legco",
          "kind" => "vote_block",
          "ref" => "urn:legco:vote-block:1",
          "attributes" => [
            { "key" => "division", "type" => "string", "value" => "yes" },
            { "key" => "vote_count", "type" => "integer", "intValue" => 37 },
            { "key" => "quorum", "type" => "integer", "intValue" => 7 },
            { "key" => "live_stream", "type" => "boolean", "booleanValue" => true },
            { "key" => "start", "type" => "datetime",
              "dateTimeValue" => "2026-07-04T10:00:00Z" }
          ]
        },
        {
          "profile" => "ietf",
          "kind" => "wg_meeting_meta",
          "attributes" => [
            { "key" => "wg_name", "type" => "string", "value" => "quic" }
          ]
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
    expect(first.attributes.map(&:key))
      .to eq(%w[division vote_count quorum live_stream start])
  end

  it "no longer exposes the recursive `extensions[]` slot on MeetingExtension" do
    entity = subject_with_extensions
    expect(entity.extensions.first).not_to respond_to(:extensions),
      "MeetingExtension should not have a nested extensions[] slot (v2.1 tighten)"
  end

  it "reads typed values via #typed_value" do
    attrs = subject_with_extensions.extensions.first.attributes
    expect(attrs[0].typed_value).to eq("yes")
    expect(attrs[1].typed_value).to eq(37)
    expect(attrs[2].typed_value).to eq(7)
    expect(attrs[3].typed_value).to eq(true)
    expect(attrs[4].typed_value).to be_a(DateTime)
  end

  it "round-trips typed values through to_yaml and back unchanged" do
    entity = subject_with_extensions
    reloaded = described_class.from_yaml(entity.to_yaml)
    attrs = reloaded.extensions.first.attributes
    expect(attrs.map(&:typed_value)).to eq(["yes", 37, 7, true, attrs[4].typed_value])
  end

  it "accepts the v2.0 bare `value:` wire shape for back-compat" do
    legacy = described_class.from_yaml(YAML.dump(factory.merge(
      "extensions" => [{
        "profile" => "legco",
        "attributes" => [{ "key" => "k", "value" => "v" }]
      }]
    )))
    attr = legacy.extensions.first.attributes.first
    expect(attr.string_value).to eq("v")
    expect(attr.typed_value).to eq("v")
  end

  it "tolerates an empty extensions list" do
    entity = described_class.from_yaml(YAML.dump(factory.merge("extensions" => [])))
    expect(entity.extensions).to eq([])
  end
end
