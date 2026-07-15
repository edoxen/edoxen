# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::ContactRegister do
  let(:contact_a) do
    Edoxen::Contact.new(
      urn: "urn:edoxen:contact:isotc154:jianfang-zhang",
      name: [Edoxen::LocalizedName.new(spelling: "eng",
                                       value: Edoxen::Name.new(formatted: "Jianfang Zhang"))],
      kind: "person"
    )
  end

  let(:contact_b) do
    Edoxen::Contact.new(
      urn: "urn:edoxen:contact:isotc154:secretariat",
      name: [Edoxen::LocalizedName.new(spelling: "eng",
                                       value: Edoxen::Name.new(formatted: "ISO/TC 154 Secretariat"))],
      kind: "organisation"
    )
  end

  describe "round-trip" do
    it "preserves scope, title, contacts, and extensions through to_yaml/from_yaml" do
      collection = described_class.new(
        scope: "isotc154",
        title: [Edoxen::LocalizedString.new(spelling: "eng", value: "ISO/TC 154 Contacts")],
        contacts: [contact_a, contact_b]
      )

      reloaded = described_class.from_yaml(collection.to_yaml)

      expect(reloaded.scope).to eq("isotc154")
      expect(reloaded.title.first.value).to eq("ISO/TC 154 Contacts")
      expect(reloaded.contacts.size).to eq(2)
      expect(reloaded.contacts.first).to be_an(Edoxen::Contact)
      expect(reloaded.contacts.first.urn).to eq("urn:edoxen:contact:isotc154:jianfang-zhang")
      expect(reloaded.contacts.last.name.first.value.formatted).to eq("ISO/TC 154 Secretariat")
    end

    it "parses a YAML payload matching the canonical wire shape" do
      payload = {
        "scope" => "isotc154",
        "title" => [{ "spelling" => "eng", "value" => "ISO/TC 154 Contacts" }],
        "contacts" => [
          { "urn" => "urn:edoxen:contact:isotc154:jianfang-zhang",
            "kind" => "person",
            "name" => [{ "spelling" => "eng", "value" => { "formatted" => "Jianfang Zhang" } }] }
        ]
      }

      collection = described_class.from_yaml(YAML.dump(payload))

      expect(collection.scope).to eq("isotc154")
      expect(collection.contacts.first.urn).to eq("urn:edoxen:contact:isotc154:jianfang-zhang")
    end
  end

  describe "#find_by_urn" do
    let(:collection) { described_class.new(contacts: [contact_a, contact_b]) }

    it "returns the contact whose urn matches" do
      expect(collection.find_by_urn("urn:edoxen:contact:isotc154:secretariat")).to eq(contact_b)
    end

    it "returns nil when no contact matches" do
      expect(collection.find_by_urn("urn:edoxen:contact:isotc154:nobody")).to be_nil
    end

    it "returns nil on an empty collection" do
      expect(described_class.new.find_by_urn("urn:edoxen:contact:scope:any")).to be_nil
    end
  end
end
