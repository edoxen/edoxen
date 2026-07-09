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
        { "key" => "wg_name", "type" => "string", "value" => "quic" },
        { "key" => "draft_name", "type" => "string", "value" => "draft-ietf-quic-v2" }
      ]
    }
    ext = described_class.from_yaml(YAML.dump(payload))
    expect(ext.attributes).to all(be_a(Edoxen::ExtensionAttribute))
    expect(ext.attributes.map(&:key)).to eq(%w[wg_name draft_name])
  end

  # 1.0 tighten (1.0 design review): the recursive `extensions[]` slot
  # was removed. Profiles needing nesting use dotted keys in
  # `attributes[]` instead.
  it "no longer exposes the recursive `extensions[]` slot" do
    expect(described_class.new).not_to respond_to(:extensions),
                                       "MeetingExtension should not have a nested extensions[] slot (1.0 tighten)"
  end
end

RSpec.describe Edoxen::ExtensionAttribute do
  it "round-trips key + value (1.0 wire shape, string variant)" do
    ea = described_class.from_yaml(YAML.dump("key" => "k", "type" => "string", "value" => "v"))
    expect(ea.key).to eq("k")
    expect(ea.value).to eq("v")
    expect(ea.typed_value).to eq("v")
  end

  it "round-trips an integer value" do
    ea = described_class.from_yaml(YAML.dump(
                                     "key" => "quorum", "type" => "integer", "intValue" => 7
                                   ))
    expect(ea.integer_value).to eq(7)
    expect(ea.typed_value).to eq(7)
  end

  it "round-trips a float value" do
    ea = described_class.from_yaml(YAML.dump(
                                     "key" => "ratio", "type" => "float", "floatValue" => 0.75
                                   ))
    expect(ea.float_value).to eq(0.75)
    expect(ea.typed_value).to eq(0.75)
  end

  it "round-trips a boolean value" do
    ea = described_class.from_yaml(YAML.dump(
                                     "key" => "live", "type" => "boolean", "booleanValue" => true
                                   ))
    expect(ea.boolean_value).to eq(true)
    expect(ea.typed_value).to eq(true)
  end

  it "round-trips a date value" do
    ea = described_class.from_yaml(YAML.dump(
                                     "key" => "effective", "type" => "date", "dateValue" => "2026-07-04"
                                   ))
    expect(ea.date_value).to eq(Date.new(2026, 7, 4))
    expect(ea.typed_value).to eq(Date.new(2026, 7, 4))
  end

  it "round-trips a datetime value" do
    ea = described_class.from_yaml(YAML.dump(
                                     "key" => "start", "type" => "datetime",
                                     "dateTimeValue" => "2026-07-04T10:00:00Z"
                                   ))
    expect(ea.date_time_value).to be_a(DateTime)
    expect(ea.typed_value).to be_a(DateTime)
  end

  it "exposes value via #string_value alias for back-compat with 1.0 callers" do
    ea = described_class.from_yaml(YAML.dump("key" => "k", "value" => "v"))
    expect(ea.string_value).to eq("v")
    expect(ea.value).to eq("v")
  end

  it "returns nil from #typed_value when no value field is set" do
    expect(described_class.new(key: "k").typed_value).to be_nil
  end
end
