# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::VenueRegister do
  let(:venue_physical) do
    Edoxen::Venue.new(
      urn: "urn:edoxen:venue:ciml:salle-turgot",
      kind: "physical",
      name: [Edoxen::LocalizedString.new(spelling: "eng", value: "BIML HQ, Salle Turgot")],
      unlocode: "FRPAR"
    )
  end

  let(:venue_virtual) do
    Edoxen::Venue.new(
      urn: "urn:edoxen:venue:ciml:zoom-main",
      kind: "virtual",
      name: [Edoxen::LocalizedString.new(spelling: "eng", value: "Main Zoom")],
      uri: "https://oiml.zoom.us/j/12345"
    )
  end

  describe "round-trip" do
    it "preserves scope, title, venues, and extensions through to_yaml/from_yaml" do
      collection = described_class.new(
        scope: "ciml",
        title: [Edoxen::LocalizedString.new(spelling: "eng", value: "CIML Venues")],
        venues: [venue_physical, venue_virtual]
      )

      reloaded = described_class.from_yaml(collection.to_yaml)

      expect(reloaded.scope).to eq("ciml")
      expect(reloaded.venues.size).to eq(2)
      expect(reloaded.venues.first).to be_an(Edoxen::Venue)
      expect(reloaded.venues.first.urn).to eq("urn:edoxen:venue:ciml:salle-turgot")
      expect(reloaded.venues.first.unlocode).to eq("FRPAR")
      expect(reloaded.venues.last.uri).to eq("https://oiml.zoom.us/j/12345")
    end

    it "parses a YAML payload matching the canonical wire shape" do
      payload = {
        "scope" => "ciml",
        "title" => [{ "spelling" => "eng", "value" => "CIML Venues" }],
        "venues" => [
          { "urn" => "urn:edoxen:venue:ciml:salle-turgot",
            "kind" => "physical",
            "name" => [{ "spelling" => "eng", "value" => "Salle Turgot" }],
            "unlocode" => "FRPAR" }
        ]
      }

      collection = described_class.from_yaml(YAML.dump(payload))

      expect(collection.scope).to eq("ciml")
      expect(collection.venues.first.urn).to eq("urn:edoxen:venue:ciml:salle-turgot")
    end
  end

  describe "#find_by_urn" do
    let(:collection) { described_class.new(venues: [venue_physical, venue_virtual]) }

    it "returns the venue whose urn matches" do
      expect(collection.find_by_urn("urn:edoxen:venue:ciml:zoom-main")).to eq(venue_virtual)
    end

    it "returns nil when no venue matches" do
      expect(collection.find_by_urn("urn:edoxen:venue:ciml:nope")).to be_nil
    end

    it "returns nil on an empty collection" do
      expect(described_class.new.find_by_urn("urn:edoxen:venue:scope:any")).to be_nil
    end
  end
end
