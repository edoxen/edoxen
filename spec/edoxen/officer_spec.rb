# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::Officer do
  it "round-trips role + person + term" do
    payload = {
      "role" => "chair",
      "person" => { "name" => "Jane" },
      "term_start" => "2024-01-01",
      "term_end" => "2025-12-31"
    }
    o = described_class.from_yaml(YAML.dump(payload))
    expect(o.role).to eq("chair")
    expect(o.person).to be_a(Edoxen::Person)
    expect(o.term_start).to eq(Date.new(2024, 1, 1))
    expect(o.term_end).to eq(Date.new(2025, 12, 31))
  end

  describe "#current?" do
    it "is true when within term" do
      o = described_class.new(term_start: Date.new(2024, 1, 1), term_end: Date.new(2024, 12, 31))
      expect(o.current?(Date.new(2024, 6, 1))).to be true
    end

    it "is false before term starts" do
      o = described_class.new(term_start: Date.new(2024, 6, 1))
      expect(o.current?(Date.new(2024, 1, 1))).to be false
    end

    it "is false after term ends" do
      o = described_class.new(term_end: Date.new(2024, 6, 1))
      expect(o.current?(Date.new(2024, 12, 31))).to be false
    end

    it "is true when no term boundaries set" do
      o = described_class.new
      expect(o.current?(Date.today)).to be true
    end
  end
end
