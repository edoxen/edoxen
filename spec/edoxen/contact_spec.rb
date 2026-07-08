# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::Contact do
  it_behaves_like "extension host", factory: {}

  describe "LUTAML field coverage" do
    it "round-trips every admin + identity field" do
      payload = {
        "name" => [{ "spelling" => "eng", "value" => { "formatted" => "ACME Secretariat" } }],
        "kind" => "organisation",
        "role" => "secretariat",
        "title" => [{ "spelling" => "eng", "value" => "Mr" }],
        "affiliation" => [{ "spelling" => "eng", "value" => "ACME Inc." }],
        "address" => [{ "spelling" => "eng", "value" => "1 Acme Plaza" }],
        "contact_methods" => [
          { "kind" => "email", "value" => "sec@acme.org", "primary" => true }
        ],
        "identifiers" => [
          { "kind" => "ror", "value" => "04abc123" }
        ]
      }
      c = described_class.from_yaml(YAML.dump(payload))
      expect(c.name.first).to be_an(Edoxen::LocalizedName)
      expect(c.name.first.value.formatted).to eq("ACME Secretariat")
      expect(c.kind).to eq("organisation")
      expect(c.role).to eq("secretariat")
      expect(c.title.first.value).to eq("Mr")
      expect(c.affiliation.first.value).to eq("ACME Inc.")
      expect(c.address.first.value).to eq("1 Acme Plaza")
      expect(c.contact_methods.first).to be_an(Edoxen::ContactMethod)
      expect(c.identifiers.first).to be_an(Edoxen::ContactIdentifier)
    end
  end

  describe "Person inherits Contact" do
    it "is a Contact subclass" do
      expect(Edoxen::Person.ancestors).to include(described_class)
    end

    it "carries the same attributes as Contact via inheritance" do
      person = Edoxen::Person.new(
        name: [Edoxen::LocalizedName.new(spelling: "eng",
                                          value: Edoxen::Name.new(formatted: "Jane Doe"))],
        contact_methods: [Edoxen::ContactMethod.new(kind: "email", value: "jane@x.org")]
      )
      expect(person.name.first.value.formatted).to eq("Jane Doe")
      expect(person.contact_methods.first.value).to eq("jane@x.org")
    end
  end
end
