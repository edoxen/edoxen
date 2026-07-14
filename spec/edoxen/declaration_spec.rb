# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::Declaration do
  it_behaves_like "extension host", factory: {}

  describe "kind discriminator" do
    Edoxen::Enums::DECLARATION_KIND.each do |kind|
      it "accepts kind=#{kind}" do
        d = described_class.new(kind: kind)
        expect(d.kind).to eq(kind)
      end
    end

    it "does not enforce kind at construction time (lutaml-model is permissive)" do
      d = described_class.new(kind: "not-a-declaration-kind")
      expect(d.kind).to eq("not-a-declaration-kind")
    end
  end

  it "round-trips a conflict-of-interest declaration" do
    payload = {
      "kind" => "conflict_of_interest",
      "description" => [
        { "spelling" => "eng", "value" => "Member declares a conflict on agenda item 5.2." }
      ],
      "party" => [
        { "kind" => "person",
          "name" => [{ "spelling" => "eng",
                       "value" => { "formatted" => "John Smith" } }] }
      ]
    }
    d = described_class.from_yaml(YAML.dump(payload))
    expect(d.kind).to eq("conflict_of_interest")
    expect(d.description.first.value).to eq("Member declares a conflict on agenda item 5.2.")
    expect(d.party.first.name.first.value.formatted).to eq("John Smith")
    expect(d.ipr_subject_ref).to be_nil
    expect(d.ipr_target_ref).to be_nil
  end

  it "round-trips an IPR declaration with typed EntityRef subject and target" do
    payload = {
      "kind" => "ipr",
      "description" => [
        { "spelling" => "eng",
          "value" => "Member declares a patent on the technology described in clause 7." }
      ],
      "party" => [
        { "kind" => "person",
          "name" => [{ "spelling" => "eng",
                       "value" => { "formatted" => "Patent Holder" } }] }
      ],
      "ipr_subject_ref" => {
        "urn" => "urn:edoxen:ipr-subject:iso-patent-policy:2024"
      },
      "ipr_target_ref" => {
        "identifier" => { "prefix" => "ISO", "number" => "8601-1:2019" }
      }
    }
    d = described_class.from_yaml(YAML.dump(payload))
    expect(d.kind).to eq("ipr")
    expect(d.ipr_subject_ref).to be_an(Edoxen::EntityRef)
    expect(d.ipr_subject_ref.urn).to eq("urn:edoxen:ipr-subject:iso-patent-policy:2024")
    expect(d.ipr_subject_ref).to be_valid

    expect(d.ipr_target_ref).to be_an(Edoxen::EntityRef)
    expect(d.ipr_target_ref.identifier.prefix).to eq("ISO")
    expect(d.ipr_target_ref.identifier.number).to eq("8601-1:2019")
    expect(d.ipr_target_ref).to be_valid
  end

  it "round-trips a bilingual IPR declaration" do
    payload = {
      "kind" => "ipr",
      "description" => [
        { "spelling" => "eng", "value" => "Patent declared on clause 7." },
        { "spelling" => "zho-Hans", "value" => "对第7条声明了专利。" }
      ],
      "ipr_subject_ref" => { "urn" => "urn:edoxen:ipr-subject:test:1" },
      "ipr_target_ref" => { "urn" => "urn:iso:std:iso:8601:-:stage-draft" }
    }
    d = described_class.from_yaml(YAML.dump(payload))
    expect(d.description.size).to eq(2)
    expect(d.description.find { |l| l.spelling == "zho-Hans" }.value).to eq("对第7条声明了专利。")

    reloaded = described_class.from_yaml(d.to_yaml)
    expect(reloaded.description.find { |l| l.spelling == "zho-Hans" }.value).to eq("对第7条声明了专利。")
  end
end
