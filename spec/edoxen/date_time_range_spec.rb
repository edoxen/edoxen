# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::DateTimeRange do
  it "round-trips a sub-day range via from_yaml / to_yaml" do
    payload = {
      "start" => "2026-07-14T09:00:00+00:00",
      "end" => "2026-07-14T11:30:00+00:00"
    }
    r = described_class.from_yaml(YAML.dump(payload))
    # lutaml-model's :date_time type returns DateTime instances.
    expect(r.start).to eq(DateTime.new(2026, 7, 14, 9, 0, 0, "+00:00"))
    expect(r.end).to eq(DateTime.new(2026, 7, 14, 11, 30, 0, "+00:00"))

    reloaded = described_class.from_yaml(r.to_yaml)
    expect(reloaded.start).to eq(r.start)
    expect(reloaded.end).to eq(r.end)
  end

  it "is distinct from DateRange (different type for the two granularities)" do
    expect(described_class).not_to eq(Edoxen::DateRange)
    expect(described_class.attributes[:start].type).to eq(Lutaml::Model::Type::DateTime)
    expect(Edoxen::DateRange.attributes[:start].type).to eq(Lutaml::Model::Type::Date)
  end

  it "is constructible with nil endpoints (optional range)" do
    r = described_class.new
    expect(r.start).to be_nil
    expect(r.end).to be_nil
  end
end
