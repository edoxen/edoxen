# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::HostRef do
  describe "LUTAML HostType coverage" do
    Edoxen::Enums::HOST_TYPE.each do |t|
      it "round-trips type=#{t}" do
        payload = { "ref" => "acme", "type" => t, "role" => "co-host" }
        h = described_class.from_yaml(YAML.dump(payload))
        expect(h.type).to eq(t)
        expect(h.ref).to eq("acme")
      end
    end
  end

  it "carries an optional contact (Contact shape)" do
    payload = {
      "ref" => "acme", "type" => "organizer",
      "contact" => {
        "name" => [{ "spelling" => "eng", "value" => { "formatted" => "Jane" } }],
        "contact_methods" => [{ "kind" => "email", "value" => "jane@acme.org" }]
      }
    }
    h = described_class.from_yaml(YAML.dump(payload))
    expect(h.contact).to be_a(Edoxen::Contact)
    expect(h.contact.name.first.value.display).to eq("Jane")
    expect(h.contact.contact_methods.first.value).to eq("jane@acme.org")
  end
end
