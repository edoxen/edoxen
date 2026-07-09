# frozen_string_literal: true

require "spec_helper"

# `Person < Contact` is empty in Ruby on purpose — it's a pure type
# marker for individual humans, distinguished from organisations,
# departments, and roles that the same Contact base class can carry.
#
# The canonical schema "duplicates" Contact's properties onto Person
# because JSON-Schema draft-07 lacks `extends`; wire-shape parity
# therefore relies on Ruby inheritance being correct. This spec pins
# that contract: every Contact attribute MUST be present on Person
# with the same name, type, and collection flag.
RSpec.describe "Person inherits Contact attributes" do
  it "Person is a Contact subclass" do
    expect(Edoxen::Person.ancestors).to include(Edoxen::Contact)
  end

  it "declares every Contact attribute with matching name, type, and collection flag" do
    contact_attrs = Edoxen::Contact.attributes
    person_attrs = Edoxen::Person.attributes

    # Person should not declare attributes Contact does not — that
    # would break the "pure type marker" intent and the schema-side
    # shape duplication.
    extra_on_person = person_attrs.keys - contact_attrs.keys
    expect(extra_on_person).to be_empty,
                               "Person declares #{extra_on_person.inspect} that Contact does not. " \
                               "Person is a pure type marker — additions belong on Contact."

    contact_attrs.each do |name, contact_attr|
      person_attr = person_attrs[name]
      expect(person_attr).not_to be_nil, "Person is missing attribute :#{name} from Contact"

      expect(person_attr.type).to eq(contact_attr.type),
                                  "Person##{name} type=#{person_attr.type.inspect} differs from " \
                                  "Contact##{name} type=#{contact_attr.type.inspect}"
      expect(person_attr.collection?).to eq(contact_attr.collection?),
                                         "Person##{name} collection flag differs from Contact"
    end
  end

  it "round-trips a Person with the full Contact field set" do
    payload = {
      "urn" => "urn:edoxen:contact:test:jane",
      "kind" => "person",
      "role" => "secretariat",
      "name" => [{ "spelling" => "eng", "value" => { "formatted" => "Jane Doe" } }],
      "title" => [{ "spelling" => "eng", "value" => "Director" }],
      "affiliation" => [{ "spelling" => "eng", "value" => "ACME" }],
      "address" => [{ "spelling" => "eng", "value" => "1 Acme Plaza" }],
      "contact_methods" => [{ "kind" => "email", "value" => "jane@x.org" }],
      "identifiers" => [{ "kind" => "orcid", "value" => "0000-0001-0002-0003" }]
    }
    person = Edoxen::Person.from_yaml(YAML.dump(payload))

    expect(person).to be_an(Edoxen::Person)
    expect(person.name.first.value.formatted).to eq("Jane Doe")
    expect(person.title.first.value).to eq("Director")
    expect(person.contact_methods.first.value).to eq("jane@x.org")
    expect(person.identifiers.first.value).to eq("0000-0001-0002-0003")
  end
end
