# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::Deadline do
  it "round-trips a deadline" do
    d = described_class.from_yaml(YAML.dump("date" => "2024-01-10", "description" => [{ "spelling" => "eng", "value" => "Registration" }]))
    expect(d.date).to eq(Date.new(2024, 1, 10))
    expect(d.description.first.value).to eq("Registration")
  end
end
