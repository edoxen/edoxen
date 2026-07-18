# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::EntityResolver do
  let(:jane_inline) do
    Edoxen::Contact.new(
      kind: "person",
      name: [Edoxen::LocalizedName.new(spelling: "eng",
                                       value: Edoxen::Name.new(formatted: "Jane Doe"))]
    )
  end

  let(:jane_scoped) do
    Edoxen::Contact.new(
      urn: "jane",
      kind: "person",
      name: [Edoxen::LocalizedName.new(spelling: "eng",
                                       value: Edoxen::Name.new(formatted: "Jane Scoped"))]
    )
  end

  let(:jane_global) do
    Edoxen::Contact.new(
      urn: "urn:edoxen:contact:test:jane",
      kind: "person",
      name: [Edoxen::LocalizedName.new(spelling: "eng",
                                       value: Edoxen::Name.new(formatted: "Jane Global"))]
    )
  end

  let(:register) do
    Edoxen::ContactRegister.new(
      scope: "test",
      contacts: [jane_global]
    )
  end

  let(:resolver) do
    described_class.new(
      scoped: { Edoxen::Contact => [jane_scoped] },
      registers: { Edoxen::Contact => register }
    )
  end

  describe "#resolve" do
    it "returns inline entities as-is when neither ref nor local_ref is set" do
      result = resolver.resolve(jane_inline)
      expect(result).to eq(jane_inline)
    end

    it "resolves local_ref from the scoped collection" do
      ref = Edoxen::Contact.new(local_ref: "jane")
      result = resolver.resolve(ref)
      expect(result).to eq(jane_scoped)
      expect(result.name.first.value.formatted).to eq("Jane Scoped")
    end

    it "resolves ref (URN) from the global register" do
      ref = Edoxen::Contact.new(ref: "urn:edoxen:contact:test:jane")
      result = resolver.resolve(ref)
      expect(result).to eq(jane_global)
      expect(result.name.first.value.formatted).to eq("Jane Global")
    end

    it "returns nil when local_ref does not match any scoped member" do
      ref = Edoxen::Contact.new(local_ref: "nobody")
      expect(resolver.resolve(ref)).to be_nil
    end

    it "returns nil when ref does not match any register member" do
      ref = Edoxen::Contact.new(ref: "urn:edoxen:contact:test:nobody")
      expect(resolver.resolve(ref)).to be_nil
    end

    it "does not mutate the input entity" do
      ref = Edoxen::Contact.new(local_ref: "jane")
      original_local_ref = ref.local_ref
      resolver.resolve(ref)
      expect(ref.local_ref).to eq(original_local_ref)
    end

    it "resolves a Body local_ref against scoped bodies by code (Body has no urn)" do
      ciml = Edoxen::Body.new(code: "ciml",
                              name: [Edoxen::LocalizedString.new(spelling: "eng", value: "CIML")])
      body_resolver = described_class.new(scoped: { Edoxen::Body => [ciml] })
      result = body_resolver.resolve(Edoxen::Body.new(local_ref: "ciml"))
      expect(result).to eq(ciml)
    end
  end

  describe "#resolve_all" do
    it "resolves a mixed list of inline and referenced entities" do
      local_ref = Edoxen::Contact.new(local_ref: "jane")
      results = resolver.resolve_all([jane_inline, local_ref])
      expect(results[0]).to eq(jane_inline)
      expect(results[1]).to eq(jane_scoped)
    end
  end
end
