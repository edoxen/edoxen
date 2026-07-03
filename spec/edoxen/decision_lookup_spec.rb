# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::Decision, "#in_language" do
  let(:decision) do
    described_class.new(
      identifier: [Edoxen::StructuredIdentifier.new(prefix: "X", number: "1")],
      localizations: [
        Edoxen::Localization.new(language_code: "fra", script: "Latn", title: "Titre français"),
        Edoxen::Localization.new(language_code: "deu", script: "Latn", title: "Deutscher Titel"),
        Edoxen::Localization.new(language_code: "eng", script: "Latn", title: "English Title")
      ]
    )
  end

  it "returns the localization whose language_code matches" do
    expect(decision.in_language("fra").title).to eq("Titre français")
    expect(decision.in_language("deu").title).to eq("Deutscher Titel")
    expect(decision.in_language("eng").title).to eq("English Title")
  end

  it "accepts symbols as well as strings" do
    expect(decision.in_language(:fra).title).to eq("Titre français")
  end

  it "returns nil when the language is absent and fallback is disabled" do
    expect(decision.in_language("rus")).to be_nil
  end

  it "falls back to the first localization when fallback: true" do
    expect(decision.in_language("rus", fallback: true).language_code).to eq("fra")
  end
end

RSpec.describe Edoxen::Decision, "#primary_localization" do
  it "prefers English when present" do
    r = Edoxen::Decision.new(
      identifier: [Edoxen::StructuredIdentifier.new(prefix: "X", number: "1")],
      localizations: [
        Edoxen::Localization.new(language_code: "fra", title: "Français"),
        Edoxen::Localization.new(language_code: "eng", title: "English")
      ]
    )
    expect(r.primary_localization.title).to eq("English")
  end

  it "falls back to the first localization when English is absent" do
    r = Edoxen::Decision.new(
      identifier: [Edoxen::StructuredIdentifier.new(prefix: "X", number: "1")],
      localizations: [
        Edoxen::Localization.new(language_code: "fra", title: "Français"),
        Edoxen::Localization.new(language_code: "deu", title: "Deutsch")
      ]
    )
    expect(r.primary_localization.title).to eq("Français")
  end

  it "returns nil when no localizations are declared" do
    r = Edoxen::Decision.new
    expect(r.primary_localization).to be_nil
  end

  it "works against the multilingual fixture" do
    collection = Edoxen::DecisionCollection.from_yaml(
      File.read(File.expand_path("../fixtures/ciml-56-44.yaml", __dir__))
    )
    decision = collection.decisions.first
    expect(decision.in_language("fra").title).to include("Décision")
    expect(decision.in_language("eng").title).to include("Decision")
    expect(decision.primary_localization.language_code).to eq("eng")
  end
end
