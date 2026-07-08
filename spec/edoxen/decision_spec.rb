# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::Decision do
  it_behaves_like "extension host",
                  factory: { "identifier" => [{ "prefix" => "X", "number" => "1" }],
                             "localizations" => [{ "language_code" => "eng", "title" => [{ "spelling" => "eng", "value" => "T" }] }] }

  describe "language-agnostic admin fields (LUTAML canonical)" do
    it "carries identifier as a collection of StructuredIdentifier" do
      payload = {
        "identifier" => [
          { "prefix" => "ISO", "number" => "2019-01" },
          { "prefix" => "TC154", "number" => "WG1" }
        ],
        "kind" => "resolution",
        "localizations" => [
          { "language_code" => "eng", "script" => "Latn", "title" => [{ "spelling" => "eng", "value" => "T" }] }
        ]
      }
      r = described_class.from_yaml(YAML.dump(payload))
      expect(r.identifier).to be_an(Array)
      expect(r.identifier.size).to eq(2)
      expect(r.identifier.first).to be_a(Edoxen::StructuredIdentifier)
      expect(r.kind).to eq("resolution")
    end

    it "carries LUTAML DecisionKind values" do
      Edoxen::Enums::DECISION_KIND.each do |k|
        r = described_class.new(kind: k, identifier: [Edoxen::StructuredIdentifier.new(prefix: "X", number: "1")])
        expect(r.kind).to eq(k)
      end
    end

    it "carries doi, urn, agenda_item, dates, categories, meeting, relations, urls" do
      payload = {
        "identifier" => [{ "prefix" => "X", "number" => "1" }],
        "doi" => "10.1234/abc",
        "urn" => "urn:x:y",
        "agenda_item" => "11.2",
        "dates" => [{ "date" => "2024-01-15", "type" => "adoption" }],
        "categories" => ["WG 1"],
        "meeting" => { "venue" => "Online", "date" => "2024-01-15" },
        "relations" => [
          {
            "source" => { "prefix" => "X", "number" => "1" },
            "destination" => { "prefix" => "X", "number" => "2" },
            "type" => "updates"
          }
        ],
        "urls" => [{ "kind" => "access", "ref" => "https://example.com", "format" => "html" }],
        "localizations" => [
          { "language_code" => "eng", "script" => "Latn", "title" => [{ "spelling" => "eng", "value" => "T" }] }
        ]
      }
      r = described_class.from_yaml(YAML.dump(payload))
      expect(r.doi).to eq("10.1234/abc")
      expect(r.urn).to eq("urn:x:y")
      expect(r.agenda_item).to eq("11.2")
      expect(r.dates.first).to be_a(Edoxen::DecisionDate)
      expect(r.categories).to eq(["WG 1"])
      expect(r.meeting).to be_a(Edoxen::MeetingIdentifier)
      expect(r.relations.first).to be_a(Edoxen::DecisionRelation)
      expect(r.urls.first).to be_a(Edoxen::Url)
    end
  end

  describe "procedural state machine fields" do
    it "carries status as a DecisionStatus" do
      Edoxen::Enums::DECISION_STATUS.each do |s|
        d = described_class.new(status: s)
        expect(d.status).to eq(s)
      end
    end

    it "links back to its motion and component via URN strings" do
      d = described_class.new(
        brought_by_motions: ["urn:edoxen:motion:1"],
        about_topics: ["urn:edoxen:topic:5"],
        made_in_component: "urn:edoxen:component:plenary-3"
      )
      expect(d.brought_by_motions).to eq(["urn:edoxen:motion:1"])
      expect(d.about_topics).to eq(["urn:edoxen:topic:5"])
      expect(d.made_in_component).to eq("urn:edoxen:component:plenary-3")
    end
  end

  describe "1.0 per-field Localized fields" do
    it "exposes title, subject, message, considering as Localized<String>[]" do
      d = described_class.new
      expect(d).to respond_to(:title)
      expect(d).to respond_to(:subject)
      expect(d).to respond_to(:message)
      expect(d).to respond_to(:considering)
      expect(d).to respond_to(:considerations)
      expect(d).to respond_to(:approvals)
      expect(d).to respond_to(:actions)
    end

    it "round-trips per-field Localized content" do
      payload = {
        "identifier" => [{ "prefix" => "X", "number" => "1" }],
        "kind" => "resolution",
        "title" => [{ "spelling" => "eng", "value" => "Title" }],
        "subject" => [{ "spelling" => "eng", "value" => "Subject" }],
        "actions" => [
          {
            "type" => "approves",
            "date_effective" => { "date" => "2024-01-15", "type" => "adoption" },
            "message" => [{ "spelling" => "eng", "value" => "approves" }]
          }
        ]
      }
      r = described_class.from_yaml(YAML.dump(payload))
      expect(r.title.first.value).to eq("Title")
      expect(r.subject.first.value).to eq("Subject")
      expect(r.actions.first).to be_a(Edoxen::Action)
    end
  end

  describe "real-world fixtures round-trip" do
    Dir.glob(File.expand_path("../fixtures/*.yaml", __dir__)).each do |fixture|
      it "round-trips #{File.basename(fixture)}" do
        collection = Edoxen::DecisionCollection.from_yaml(File.read(fixture))
        reloaded = Edoxen::DecisionCollection.from_yaml(collection.to_yaml)
        expect(reloaded.decisions.size).to eq(collection.decisions.size)
        expect(reloaded.decisions.first.identifier).to eq(collection.decisions.first.identifier)
      end
    end
  end
end
