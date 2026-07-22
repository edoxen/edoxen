# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::Body do
  describe "#local_lookup_key" do
    it "returns the code (Bodies have no urn — keyed by code in scoped collections)" do
      body = described_class.new(code: "ciml")
      expect(body.local_lookup_key).to eq("ciml")
    end

    it "is nil when no code is set" do
      expect(described_class.new.local_lookup_key).to be_nil
    end
  end

  describe "#reference?" do
    it "is true when ref is set" do
      expect(described_class.new(ref: "urn:edoxen:body:ciml")).to be_reference
    end

    it "is true when local_ref is set" do
      expect(described_class.new(local_ref: "ciml")).to be_reference
    end

    it "is false when neither ref nor local_ref is set" do
      expect(described_class.new(code: "ciml")).not_to be_reference
    end
  end
end
