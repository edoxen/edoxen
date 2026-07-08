# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::Attendance do
  it_behaves_like "extension host",
                  factory: { "person" => { "name" => [{ "spelling" => "eng", "value" => { "formatted" => "Jane" } }] }, "status" => "present" }

  describe "LUTAML ParticipationStatus coverage" do
    Edoxen::Enums::PARTICIPATION_STATUS.each do |status|
      it "round-trips status=#{status}" do
        payload = {
          "person" => { "name" => [{ "spelling" => "eng", "value" => { "formatted" => "Jane" } }] },
          "status" => status,
          "affiliation" => "Acme"
        }
        a = described_class.from_yaml(YAML.dump(payload))
        expect(a.status).to eq(status)
        expect(a.person).to be_a(Edoxen::Person)
        expect(a.affiliation).to eq("Acme")
      end
    end
  end

  it "carries an optional proxy_for Person" do
    payload = {
      "person" => { "name" => [{ "spelling" => "eng", "value" => { "formatted" => "Substitute" } }] },
      "status" => "present",
      "proxy_for" => { "name" => [{ "spelling" => "eng", "value" => { "formatted" => "Original" } }] }
    }
    a = described_class.from_yaml(YAML.dump(payload))
    expect(a.proxy_for).to be_a(Edoxen::Person)
    expect(a.proxy_for.name.first.value.display).to eq("Original")
  end

  it "round-trips through YAML" do
    payload = {
      "person" => { "name" => [{ "spelling" => "eng", "value" => { "formatted" => "Jane" } }], "affiliation" => [{ "spelling" => "eng", "value" => "ISO" }] },
      "status" => "present",
      "notes" => "Arrived late"
    }
    a = described_class.from_yaml(YAML.dump(payload))
    reload = described_class.from_yaml(a.to_yaml)
    expect(reload.status).to eq("present")
    expect(reload.notes).to eq("Arrived late")
    expect(reload.person.name.first.value.display).to eq("Jane")
  end
end
