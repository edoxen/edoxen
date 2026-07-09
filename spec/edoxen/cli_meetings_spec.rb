# frozen_string_literal: true

require "spec_helper"
require "open3"
require "tmpdir"
require "fileutils"

# Integration spec for the meeting-side CLI subcommands. Spawns the
# real exe/edoxen process via Open3.capture3 — no doubles.
RSpec.describe "edoxen CLI meeting subcommands" do
  let(:cli_bin) { File.expand_path("../../exe/edoxen", __dir__) }
  let(:meetings_dir) { File.expand_path("../fixtures/meetings", __dir__) }
  let(:tmp_dir) { Dir.mktmpdir }

  after { FileUtils.remove_entry(tmp_dir) if File.directory?(tmp_dir) }

  def run_cli(*args)
    env = { "RUBYOPT" => "-I#{File.expand_path("../../lib", __dir__)}" }
    stdout, stderr, status = Open3.capture3(env, "bundle", "exec", "ruby", cli_bin, *args,
                                            chdir: File.expand_path("../..", __dir__))
    [stdout, stderr, status]
  end

  describe "validate-meetings subcommand" do
    it "exits 0 and prints VALID for conforming meeting fixtures" do
      stdout, _stderr, status = run_cli("validate-meetings", "#{meetings_dir}/simple-meeting.yaml")
      expect(status.exitstatus).to eq(0)
      expect(stdout).to include("VALID")
    end

    it "exits 0 on the full meetings directory via glob" do
      # The Windows + Open3 + bundler + glob-arg combination is flaky
      # in CI — sometimes the spawned process produces no stdout. Skip
      # on Windows; the macOS/Linux runs cover the same code path.
      skip "Windows + Open3 + bundle + glob is flaky in CI" if Gem.win_platform?

      pattern = File.join(meetings_dir, "*.yaml")
      stdout, _stderr, status = run_cli("validate-meetings", pattern)
      expect(status.exitstatus).to eq(0)
      expect(stdout).to include("Success rate: 100.0%")
    end

    it "exits non-zero on a glob that matches no file" do
      stdout, stderr, status = run_cli("validate-meetings", "no-such-meeting-*.yaml")
      expect(status.exitstatus).not_to eq(0)
      expect([stdout, stderr].join("\n")).to include("No files found")
    end

    it "exits non-zero and lists errors for an invalid meeting" do
      bad = File.join(tmp_dir, "bad-meeting.yaml")
      File.write(bad, <<~YAML)
        ---
        identifier:
          - prefix: X
            number: "1"
        type: not-a-real-meeting-type
      YAML
      stdout, _stderr, status = run_cli("validate-meetings", bad)
      expect(status.exitstatus).not_to eq(0)
      expect(stdout).to include("INVALID")
    end

    it "validates a top-level MeetingSeries fixture" do
      stdout, _stderr, status = run_cli(
        "validate-meetings", "#{meetings_dir}/ciml-series.yaml"
      )
      expect(status.exitstatus).to eq(0)
      expect(stdout).to include("VALID")
    end
  end

  describe "meetings loader shape detection" do
    it "loads a MeetingCollection via the :meetings key" do
      content = YAML.dump(
        "metadata" => { "title" => [{ "spelling" => "eng", "value" => "All" }] },
        "meetings" => [
          { "identifier" => [{ "prefix" => "X", "number" => "1" }],
            "type" => "plenary" }
        ]
      )
      loaded = Edoxen::Cli.meetings_kind(YAML.safe_load(content))
      expect(loaded).to eq(:collection)
    end

    it "loads a MeetingSeries via meeting_refs" do
      content = YAML.dump(
        "identifier" => [{ "prefix" => "CIML", "number" => "series" }],
        "meeting_refs" => ["urn:x:m:1"]
      )
      loaded = Edoxen::Cli.meetings_kind(YAML.safe_load(content))
      expect(loaded).to eq(:series)
    end

    it "loads a MeetingSeries via recurrence (no meeting_refs)" do
      content = YAML.dump(
        "identifier" => [{ "prefix" => "CIML", "number" => "series" }],
        "recurrence" => { "freq" => "yearly" }
      )
      loaded = Edoxen::Cli.meetings_kind(YAML.safe_load(content))
      expect(loaded).to eq(:series)
    end

    it "falls back to :meeting for a single Meeting shape" do
      content = YAML.dump(
        "identifier" => [{ "prefix" => "X", "number" => "1" }],
        "type" => "plenary"
      )
      loaded = Edoxen::Cli.meetings_kind(YAML.safe_load(content))
      expect(loaded).to eq(:meeting)
    end
  end

  describe "normalize-meetings subcommand" do
    it "round-trips a meeting YAML to an --output directory" do
      stdout, _stderr, status = run_cli(
        "normalize-meetings", "#{meetings_dir}/ciml-56-meeting.yaml", "--output", tmp_dir
      )
      expect(status.exitstatus).to eq(0)
      out = File.join(tmp_dir, "ciml-56-meeting.yaml")
      expect(File.exist?(out)).to be true
      expect(stdout).to include("NORMALIZED")

      # Single-Meeting files round-trip as Meeting; multi-Meeting files
      # round-trip as MeetingCollection. Both shapes are valid.
      original = Edoxen::Meeting.from_yaml(File.read("#{meetings_dir}/ciml-56-meeting.yaml"))
      normalized = Edoxen::Meeting.from_yaml(File.read(out))
      expect(normalized.identifier).to eq(original.identifier)
      expect(normalized.title.size).to eq(original.title.size)
    end

    it "errors when neither --output nor --inplace is given" do
      stdout, stderr, status = run_cli("normalize-meetings", "#{meetings_dir}/simple-meeting.yaml")
      expect(status.exitstatus).not_to eq(0)
      expect([stdout, stderr].join("\n")).to include("Must specify either")
    end

    it "errors when both --output and --inplace are given" do
      stdout, stderr, status = run_cli(
        "normalize-meetings", "#{meetings_dir}/simple-meeting.yaml",
        "--output", tmp_dir, "--inplace"
      )
      expect(status.exitstatus).not_to eq(0)
      expect([stdout, stderr].join("\n")).to include("Cannot use both")
    end
  end

  describe "help" do
    it "lists the meeting subcommands" do
      stdout, _stderr, status = run_cli("help")
      expect(status.exitstatus).to eq(0)
      expect(stdout).to include("validate-meetings")
      expect(stdout).to include("normalize-meetings")
      # Resolution-side commands are still listed:
      expect(stdout).to include("validate")
      expect(stdout).to include("normalize")
    end
  end
end
