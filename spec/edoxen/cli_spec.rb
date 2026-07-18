# frozen_string_literal: true

require "spec_helper"
require "open3"
require "tmpdir"
require "fileutils"

# Integration spec for the CLI. The CLI is intentionally thin: it glues
# SchemaValidator and DecisionCollection.from_yaml. Tests run the real
# CLI process (no Thor mocks, no doubles) against fixture files in tmp/
# so they don't mutate the repo.
RSpec.describe Edoxen::Cli do
  let(:cli_bin) { File.expand_path("../../exe/edoxen", __dir__) }
  let(:fixtures_dir) { File.expand_path("../fixtures", __dir__) }
  let(:tmp_dir) { Dir.mktmpdir }

  after { FileUtils.remove_entry(tmp_dir) if File.directory?(tmp_dir) }

  def run_cli(*args)
    env = { "RUBYOPT" => "-I#{File.expand_path("../../lib", __dir__)}" }
    stdout, stderr, status = Open3.capture3(env, "bundle", "exec", "ruby", cli_bin, *args,
                                            chdir: File.expand_path("../..", __dir__))
    [stdout, stderr, status]
  end

  # Builds a tiny link-checker fixture tree in `dir`. `resolved:`
  # controls whether the DecisionCollection's `meeting_urn` matches
  # the indexed Meeting.
  def write_link_fixtures(dir, resolved:)
    meeting_urn = format("urn:oiml:ciml:meeting:ciml-%<n>s", n: resolved ? "1" : "99")
    File.write(File.join(dir, "meeting.yaml"), <<~YAML)
      ---
      identifier:
      - prefix: CIML
        number: '1'
      urn: urn:oiml:ciml:meeting:ciml-1
      type: plenary
    YAML
    File.write(File.join(dir, "decisions.yaml"), <<~YAML)
      ---
      metadata:
        meeting_urn: #{meeting_urn}
      decisions: []
    YAML
  end

  describe "validate subcommand" do
    it "exits 0 and prints ✅ VALID for conforming fixtures" do
      stdout, _stderr, status = run_cli("validate", "#{fixtures_dir}/ciml-56-44.yaml")
      expect(status.exitstatus).to eq(0)
      expect(stdout).to include("✅ VALID")
    end

    it "validates a ContactRegister fixture via the decision-side oneOf" do
      stdout, _stderr, status = run_cli("validate", "#{fixtures_dir}/contacts.yaml")
      expect(status.exitstatus).to eq(0)
      expect(stdout).to include("VALID")
    end

    it "validates a VenueRegister fixture via the decision-side oneOf" do
      stdout, _stderr, status = run_cli("validate", "#{fixtures_dir}/venues.yaml")
      expect(status.exitstatus).to eq(0)
      expect(stdout).to include("VALID")
    end

    it "exits non-zero on a glob pattern that matches no file" do
      stdout, stderr, status = run_cli("validate", "no-such-file-*.yaml")
      expect(status.exitstatus).not_to eq(0)
      expect([stdout, stderr].join("\n")).to include("No files found")
    end

    it "exits non-zero and lists errors for files that violate the schema" do
      bad = File.join(tmp_dir, "bad.yaml")
      File.write(bad, <<~YAML)
        ---
        decisions:
          - identifier:
              - prefix: X
                number: "1"
            kind: not-a-valid-decision-kind
      YAML
      stdout, _stderr, status = run_cli("validate", bad)
      expect(status.exitstatus).not_to eq(0)
      expect(stdout).to include("INVALID")
      expect(stdout).to match(/pattern|not one of/i)
    end
  end

  describe "decision loader shape detection" do
    it "loads a ContactRegister via the :contacts key" do
      content = YAML.dump(
        "scope" => "test",
        "contacts" => [{ "urn" => "urn:edoxen:contact:test:a",
                         "kind" => "person",
                         "name" => [{ "spelling" => "eng",
                                      "value" => { "formatted" => "A" } }] }]
      )
      loaded = Edoxen::Cli::Batch.decision_kind(YAML.safe_load(content))
      expect(loaded).to eq(:contacts)
    end

    it "loads a VenueRegister via the :venues key" do
      content = YAML.dump(
        "scope" => "test",
        "venues" => [{ "urn" => "urn:edoxen:venue:test:a",
                       "kind" => "physical" }]
      )
      loaded = Edoxen::Cli::Batch.decision_kind(YAML.safe_load(content))
      expect(loaded).to eq(:venues)
    end

    it "falls back to :decisions for a DecisionCollection shape" do
      content = YAML.dump(
        "metadata" => { "title" => [{ "spelling" => "eng", "value" => "X" }] },
        "decisions" => []
      )
      loaded = Edoxen::Cli::Batch.decision_kind(YAML.safe_load(content))
      expect(loaded).to eq(:decisions)
    end
  end

  describe "normalize subcommand" do
    it "round-trips a single file to an --output directory" do
      stdout, _stderr, status = run_cli("normalize", "#{fixtures_dir}/ciml-56-44.yaml", "--output", tmp_dir)
      expect(status.exitstatus).to eq(0)
      out = File.join(tmp_dir, "ciml-56-44.yaml")
      expect(File.exist?(out)).to be true
      expect(stdout).to include("NORMALIZED")

      original = Edoxen::DecisionCollection.from_yaml(File.read("#{fixtures_dir}/ciml-56-44.yaml"))
      normalized = Edoxen::DecisionCollection.from_yaml(File.read(out))
      expect(normalized.decisions.size).to eq(original.decisions.size)
    end

    it "errors when neither --output nor --inplace is given" do
      stdout, stderr, status = run_cli("normalize", "#{fixtures_dir}/ciml-56-44.yaml")
      expect(status.exitstatus).not_to eq(0)
      expect([stdout, stderr].join("\n")).to include("Must specify either")
    end

    it "errors when both --output and --inplace are given" do
      stdout, stderr, status = run_cli(
        "normalize", "#{fixtures_dir}/ciml-56-44.yaml",
        "--output", tmp_dir, "--inplace"
      )
      expect(status.exitstatus).not_to eq(0)
      expect([stdout, stderr].join("\n")).to include("Cannot use both")
    end
  end

  describe "check-links subcommand" do
    it "exits 0 and reports no errors when all links resolve" do
      write_link_fixtures(tmp_dir, resolved: true)
      stdout, _stderr, status = run_cli("check-links", tmp_dir)
      expect(status.exitstatus).to eq(0)
      expect(stdout).to include("No broken or duplicate links")
    end

    it "exits non-zero and prints the dangling URN with file:line" do
      write_link_fixtures(tmp_dir, resolved: false)
      stdout, _stderr, status = run_cli("check-links", tmp_dir)
      expect(status.exitstatus).not_to eq(0)
      expect(stdout).to include("Found 1 link error")
      expect(stdout).to match(/decisions\.yaml:\d+: metadata\.meeting_urn/)
      expect(stdout).to include("no matching Meeting")
    end

    it "exits non-zero when a directory argument is missing" do
      stdout, stderr, status = run_cli("check-links", "/no/such/dir")
      expect(status.exitstatus).not_to eq(0)
      expect([stdout, stderr].join("\n")).to include("not a directory")
    end

    it "reports a duplicate Meeting URN with both files" do
      meeting_yaml = <<~YAML
        ---
        identifier:
        - prefix: CIML
          number: '55'
        urn: urn:oiml:ciml:meeting:ciml-55
        type: plenary
      YAML
      File.write(File.join(tmp_dir, "meeting-a.yaml"), meeting_yaml)
      File.write(File.join(tmp_dir, "meeting-b.yaml"), meeting_yaml)
      stdout, _stderr, status = run_cli("check-links", tmp_dir)
      expect(status.exitstatus).not_to eq(0)
      expect(stdout).to include("duplicate Meeting URN")
      expect(stdout).to include("meeting-a.yaml")
      expect(stdout).to include("meeting-b.yaml")
    end
  end
end
