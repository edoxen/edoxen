# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::VotingCounts do
  describe "#total" do
    it "sums all four counts" do
      expect(described_class.new(ayes: 5, noes: 3, abstentions: 2, absent: 1).total).to eq(11)
    end

    it "treats nil counts as zero" do
      expect(described_class.new.total).to eq(0)
    end
  end

  describe "#margin" do
    it "returns ayes - noes" do
      expect(described_class.new(ayes: 7, noes: 4).margin).to eq(3)
    end

    it "is negative when noes > ayes" do
      expect(described_class.new(ayes: 2, noes: 6).margin).to eq(-4)
    end
  end

  describe "#tied?" do
    it "returns true when ayes == noes" do
      expect(described_class.new(ayes: 4, noes: 4)).to be_tied
    end

    it "returns false when ayes != noes" do
      expect(described_class.new(ayes: 4, noes: 5)).not_to be_tied
    end
  end
end
