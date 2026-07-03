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

  describe "validate subcommand" do
    it "exits 0 and prints ✅ VALID for conforming fixtures" do
      stdout, _stderr, status = run_cli("validate", "#{fixtures_dir}/ciml-56-44.yaml")
      expect(status.exitstatus).to eq(0)
      expect(stdout).to include("✅ VALID")
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
        metadata:
          title: T
        decisions:
          - identifier:
              - prefix: X
                number: "1"
            localizations:
              - language_code: not-three-letter
                script: Latn
                title: T
      YAML
      stdout, _stderr, status = run_cli("validate", bad)
      expect(status.exitstatus).not_to eq(0)
      expect(stdout).to include("INVALID")
      expect(stdout).to match(/pattern|not one of/i)
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
end
