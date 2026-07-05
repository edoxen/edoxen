# frozen_string_literal: true

require "spec_helper"

RSpec.describe "TODO 46 — short canonical enums + body_vocabulary" do
  describe "canonical enum constants" do
    it "DecisionKindCanonical has 5 values (the v2.1 cap)" do
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
end
