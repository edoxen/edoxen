# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::Agenda do
  it_behaves_like "extension host", factory: {}

  describe "LUTAML AgendaStatus coverage" do
    Edoxen::Enums::AGENDA_STATUS.each do |s|
      it "round-trips status=#{s}" do
        a = described_class.from_yaml(YAML.dump("status" => s))
        expect(a.status).to eq(s)
      end
    end
  end

  it "carries items as AgendaItem objects" do
    payload = {
      "status" => "final",
      "items" => [
        { "label" => "1", "title" => "Opening", "kind" => "opening" },
        { "label" => "2", "title" => "Approval of agenda", "kind" => "numbered" }
      ]
    }
    a = described_class.from_yaml(YAML.dump(payload))
    expect(a.items.size).to eq(2)
    expect(a.items).to all(be_a(Edoxen::AgendaItem))
  end

  describe "#find_item" do
    let(:agenda) do
      described_class.from_yaml(YAML.dump(
                                  "items" => [
                                    { "label" => "1", "title" => "First" },
                                    { "label" => "5.2", "title" => "Sub-item" }
                                  ]
                                ))
    end

    it "finds by exact label" do
      expect(agenda.find_item("5.2").title).to eq("Sub-item")
    end

    it "returns nil when no label matches" do
      expect(agenda.find_item("99")).to be_nil
    end

    it "accepts non-string labels (coerces to_s)" do
      expect(agenda.find_item(1).title).to eq("First")
    end
  end
end
