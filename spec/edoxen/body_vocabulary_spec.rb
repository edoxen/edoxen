# frozen_string_literal: true

require "spec_helper"

RSpec.describe "TODO 46 — short canonical enums + body_vocabulary" do
  describe "canonical enum constants" do
    it "DecisionKindCanonical has 5 values (the 1.0 cap)" do
      expect(Edoxen::Enums::DECISION_KIND_CANONICAL.size).to eq(5)
      expect(Edoxen::Enums::DECISION_KIND_CANONICAL).to eq(
        %w[decision recommendation statement finding other]
      )
    end

    it "MeetingTypeCanonical has 4 values (no `other`)" do
      expect(Edoxen::Enums::MEETING_TYPE_CANONICAL.size).to eq(4)
      expect(Edoxen::Enums::MEETING_TYPE_CANONICAL).to eq(
        %w[plenary governing working advisory]
      )
    end

    it "ComponentKindCanonical has 5 values (with temporary `other` escape)" do
      expect(Edoxen::Enums::COMPONENT_KIND_CANONICAL.size).to eq(5)
      expect(Edoxen::Enums::COMPONENT_KIND_CANONICAL).to eq(
        %w[deliberative working ceremonial break other]
      )
    end

    # Architectural invariant (TODO.refactor/1.0-design): canonical enums cap
    # at 5. Bodies extend via `body_type: String` + per-dataset
    # `body_vocabulary[]`, NOT by growing the canonical enum. A future
    # PR that adds a sixth value silently breaks the design — this
    # example fails first.
    it "every *_CANONICAL enum is within the 1.0 cap of 5" do
      %i[DECISION_KIND_CANONICAL MEETING_TYPE_CANONICAL COMPONENT_KIND_CANONICAL].each do |c|
        size = Edoxen::Enums.const_get(c).size
        expect(size).to be <= 5,
                        "#{c} has #{size} values; the 1.0 canonical cap is 5. " \
                        "Extend via body_vocabulary instead."
      end
    end
  end

  describe "body_type field on the three core entities" do
    it "Decision carries body_type" do
      d = Edoxen::Decision.new(body_type: "Resolution")
      expect(d.body_type).to eq("Resolution")
    end

    it "Meeting carries body_type" do
      m = Edoxen::Meeting.new(body_type: "CIML Meeting")
      expect(m.body_type).to eq("CIML Meeting")
    end

    it "MeetingComponent carries body_type" do
      c = Edoxen::MeetingComponent.new(body_type: "Working Group Session")
      expect(c.body_type).to eq("Working Group Session")
    end
  end

  describe Edoxen::BodyVocabularyEntry do
    it "round-trips body_type + canonical_type + definition" do
      entry = described_class.from_yaml(YAML.dump(
                                          "body_type" => "CIML Meeting",
                                          "canonical_type" => "plenary",
                                          "definition" => "Annual decision-making meeting of the CIML"
                                        ))
      expect(entry.body_type).to eq("CIML Meeting")
      expect(entry.canonical_type).to eq("plenary")
      expect(entry.definition).to eq("Annual decision-making meeting of the CIML")
    end
  end

  describe "DecisionMetadata#canonical_type_for" do
    let(:metadata) do
      Edoxen::DecisionMetadata.new(
        body_vocabulary: [
          Edoxen::BodyVocabularyEntry.new(body_type: "Resolution", canonical_type: "decision"),
          Edoxen::BodyVocabularyEntry.new(body_type: "Order", canonical_type: "decision"),
          Edoxen::BodyVocabularyEntry.new(body_type: "Recommendation", canonical_type: "recommendation")
        ]
      )
    end

    it "resolves a known body_type to its canonical_type" do
      expect(metadata.canonical_type_for("Resolution")).to eq("decision")
      expect(metadata.canonical_type_for("Order")).to eq("decision")
      expect(metadata.canonical_type_for("Recommendation")).to eq("recommendation")
    end

    it "is permissive — returns the body_type unchanged when no entry matches" do
      expect(metadata.canonical_type_for("Unknown Body Type")).to eq("Unknown Body Type")
    end

    it "returns nil for nil body_type" do
      expect(metadata.canonical_type_for(nil)).to be_nil
    end

    it "returns the body_type when no vocabulary is declared" do
      empty = Edoxen::DecisionMetadata.new
      expect(empty.canonical_type_for("Resolution")).to eq("Resolution")
    end
  end

  describe "MeetingCollectionMetadata#canonical_type_for" do
    let(:metadata) do
      Edoxen::MeetingCollectionMetadata.new(
        body_vocabulary: [
          Edoxen::BodyVocabularyEntry.new(body_type: "CIML Meeting", canonical_type: "plenary"),
          Edoxen::BodyVocabularyEntry.new(body_type: "Board Meeting", canonical_type: "governing")
        ]
      )
    end

    it "resolves a known body_type to its canonical_type" do
      expect(metadata.canonical_type_for("CIML Meeting")).to eq("plenary")
      expect(metadata.canonical_type_for("Board Meeting")).to eq("governing")
    end

    it "is permissive on unknown body_types" do
      expect(metadata.canonical_type_for("Mystery Meeting")).to eq("Mystery Meeting")
    end
  end

  # End-to-end YAML round-trip: parses a metadata block as it appears
  # in a real fixture, exercises the lookup via the parsed Ruby object,
  # then re-serialises and re-parses to confirm shape preservation.
  describe "DecisionMetadata YAML round-trip with body_vocabulary" do
    let(:yaml) do
      YAML.dump(
        "body_vocabulary" => [
          { "body_type" => "Resolution", "canonical_type" => "decision",
            "definition" => "Formal decision adopted by vote" },
          { "body_type" => "Order", "canonical_type" => "decision" }
        ]
      )
    end

    it "parses body_vocabulary into typed entries" do
      metadata = Edoxen::DecisionMetadata.from_yaml(yaml)
      expect(metadata.body_vocabulary).to be_an(Array)
      expect(metadata.body_vocabulary.size).to eq(2)
      expect(metadata.body_vocabulary.first).to be_an(Edoxen::BodyVocabularyEntry)
      expect(metadata.body_vocabulary.first.definition).to eq("Formal decision adopted by vote")
    end

    it "exercises canonical_type_for on the parsed metadata" do
      metadata = Edoxen::DecisionMetadata.from_yaml(yaml)
      expect(metadata.canonical_type_for("Resolution")).to eq("decision")
      expect(metadata.canonical_type_for("Order")).to eq("decision")
      expect(metadata.canonical_type_for("Unknown")).to eq("Unknown")
    end

    it "preserves body_vocabulary through to_yaml + from_yaml" do
      metadata = Edoxen::DecisionMetadata.from_yaml(yaml)
      reload = Edoxen::DecisionMetadata.from_yaml(metadata.to_yaml)
      expect(reload.body_vocabulary.size).to eq(2)
      expect(reload.canonical_type_for("Resolution")).to eq("decision")
    end
  end

  describe "MeetingCollectionMetadata YAML round-trip with body_vocabulary" do
    let(:yaml) do
      YAML.dump(
        "body_vocabulary" => [
          { "body_type" => "CIML Meeting", "canonical_type" => "plenary" },
          { "body_type" => "Board Meeting", "canonical_type" => "governing" }
        ]
      )
    end

    it "parses + round-trips + resolves canonical_type_for" do
      metadata = Edoxen::MeetingCollectionMetadata.from_yaml(yaml)
      expect(metadata.body_vocabulary.size).to eq(2)
      expect(metadata.canonical_type_for("CIML Meeting")).to eq("plenary")

      reload = Edoxen::MeetingCollectionMetadata.from_yaml(metadata.to_yaml)
      expect(reload.canonical_type_for("Board Meeting")).to eq("governing")
    end
  end
end
