# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::Recurrence do
  it "round-trips all BYxxx parts" do
    payload = {
      "freq" => "monthly",
      "interval" => 2,
      "count" => 12,
      "by_day" => [{ "ordinal" => 1, "weekday" => "MO" }],
      "by_month_day" => [15],
      "by_month" => [3, 6, 9, 12],
      "by_hour" => [9],
      "by_minute" => [0],
      "week_start" => "MO"
    }
    r = described_class.from_yaml(YAML.dump(payload))
    expect(r.freq).to eq("monthly")
    expect(r.interval).to eq(2)
    expect(r.count).to eq(12)
    expect(r.by_day.first).to be_a(Edoxen::RecurrenceByDay)
    expect(r.by_day.first.weekday).to eq("MO")
    expect(r.by_month_day).to eq([15])
    expect(r.by_month).to eq([3, 6, 9, 12])
    expect(r.week_start).to eq("MO")
  end

  it "defaults interval to 1" do
    expect(described_class.new.interval).to eq(1)
  end
end

RSpec.describe Edoxen::RecurrenceByDay do
  it "round-trips ordinal + weekday" do
    r = described_class.from_yaml(YAML.dump("ordinal" => -1, "weekday" => "FR"))
    expect(r.ordinal).to eq(-1)
    expect(r.weekday).to eq("FR")
  end
end
