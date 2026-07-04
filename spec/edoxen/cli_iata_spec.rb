# frozen_string_literal: true

require "spec_helper"
require "open3"

RSpec.describe "edoxen CLI iata subcommand" do
  let(:cli_bin) { File.expand_path("../../exe/edoxen", __dir__) }

  def run_cli(*args)
    env = { "RUBYOPT" => "-I#{File.expand_path("../../lib", __dir__)}" }
    Open3.capture3(env, "bundle", "exec", "ruby", cli_bin, *args,
                   chdir: File.expand_path("../..", __dir__))
  end

  it "resolves a known IATA code" do
    stdout, _stderr, status = run_cli("iata", "JFK")
    expect(status.exitstatus).to eq(0)
    expect(stdout).to include("IATA:       JFK")
    expect(stdout).to include("John F. Kennedy")
    expect(stdout).to include("Country:")
  end

  it "exits non-zero for an unknown code" do
    _stdout, _stderr, status = run_cli("iata", "ZZZ")
    expect(status.exitstatus).to eq(1)
  end

  it "accepts lowercase input" do
    stdout, _stderr, status = run_cli("iata", "jfk")
    expect(status.exitstatus).to eq(0)
    expect(stdout).to include("JFK")
  end
end
