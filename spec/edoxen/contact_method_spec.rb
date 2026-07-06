# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::ContactMethod do
  it_behaves_like "extension host", factory: {}

  describe "LUTAML ContactMethodKind coverage" do
    Edoxen::Enums::CONTACT_METHOD_KIND.each do |kind|
      it "round-trips kind=#{kind}" do
        cm = described_class.from_yaml(YAML.dump("kind" => kind, "value" => "x"))
        expect(cm.kind).to eq(kind)
      end
    end
  end

  it "round-trips value, label, primary" do
    payload = {
      "kind" => "phone",
      "value" => "+1-555-0100",
      "label" => "Office",
      "primary" => true
    }
    cm = described_class.from_yaml(YAML.dump(payload))
    expect(cm.value).to eq("+1-555-0100")
    expect(cm.label).to eq("Office")
    expect(cm.primary).to be true

    reload = described_class.from_yaml(cm.to_yaml)
    expect(reload.primary).to be true
    expect(reload.value).to eq("+1-555-0100")
  end

  it "defaults primary to nil (falsy) when not set" do
    cm = described_class.from_yaml(YAML.dump("kind" => "email", "value" => "x"))
    expect(cm.primary).to be_nil
  end
end
