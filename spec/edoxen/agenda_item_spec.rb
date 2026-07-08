# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::AgendaItem do
  it_behaves_like "extension host", factory: {}

  describe "LUTAML AgendaItemKind coverage" do
    Edoxen::Enums::AGENDA_ITEM_KIND.each do |k|
      it "round-trips kind=#{k}" do
        payload = { "label" => "1", "kind" => k, "title" => [{ "spelling" => "eng", "value" => "Item" }] }
        ai = described_class.from_yaml(YAML.dump(payload))
        expect(ai.kind).to eq(k)
      end
    end
  end

  describe "LUTAML AgendaItemOutcome coverage" do
    Edoxen::Enums::AGENDA_ITEM_OUTCOME.each do |o|
      it "round-trips outcome=#{o}" do
        payload = { "label" => "1", "outcome" => o }
        ai = described_class.from_yaml(YAML.dump(payload))
        expect(ai.outcome).to eq(o)
      end
    end
  end

  it "carries references as Reference objects" do
    payload = {
      "label" => "5.2", "title" => [{ "spelling" => "eng", "value" => "Standards" }],
      "references" => [{ "ref" => "ISO 9735-11", "kind" => "standard" }]
    }
    ai = described_class.from_yaml(YAML.dump(payload))
    expect(ai.references.first).to be_a(Edoxen::Reference)
    expect(ai.references.first.ref).to eq("ISO 9735-11")
  end

  it "carries an optional decision_ref URN" do
    ai = described_class.from_yaml(YAML.dump(
                                     "label" => "2", "decision_ref" => "urn:oiml:doc:ciml:decision:2021-01"
                                   ))
    expect(ai.decision_ref).to eq("urn:oiml:doc:ciml:decision:2021-01")
  end
end
