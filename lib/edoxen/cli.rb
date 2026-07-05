# frozen_string_literal: true

require "thor"
require "fileutils"

module Edoxen
  class Cli < Thor
    # Each top-level YAML document is either a Decision collection or a
    # Meeting (single or collection). The two share the same batch
    # scaffold (expand → header → loop → tally → exit) but differ in
    # which schema validates them and which model class loads them.
    #
    # A Profile bundles those two facts so the Thor command methods are
    # one-line delegations. Adding a third document kind (e.g. an
    # attendance-only file) is one Profile constant + one desc block —
    # no new scaffolding.
    Profile = Struct.new(:name, :schema_file, :loader) do
      def schema_path
        File.expand_path("../../schema/#{schema_file}", __dir__)
      end

      # Returns the loaded model object, raising StandardError on failure.
      # Single-vs-collection detection is up to the loader (Meeting side
      # sniffs the top-level key; Decision side always returns a
      # DecisionCollection).
      def load(content)
        loader.call(content)
      end
    end

    PROFILES = {
      decisions: Profile.new(
        "decisions", "edoxen.yaml",
        ->(content) { DecisionCollection.from_yaml(content) }
      ),
      meetings: Profile.new(
        "meetings", "meeting.yaml",
        lambda do |content|
          data = YAML.safe_load(content, permitted_classes: [Date, Time])
          if data.is_a?(Hash) && data.key?("meetings")
            MeetingCollection.from_yaml(content)
          else
            Meeting.from_yaml(content)
          end
        end
      )
    }.freeze

    # Deep module behind the per-command interface. Owns the
    # expand/sort/empty/header/loop/tally/summary/exit scaffold so
    # `validate` and `normalize` collapse to one-line delegations.
    module Batch
      # Per-file outcome. `ok` carries an optional message appended to
      # the success indicator (e.g. "NORMALIZED → /out/path"). `bad`
      # carries a list of pre-formatted error strings.
      Result = Struct.new(:status, :message, :errors) do
        def self.ok(message = nil)
          new(:ok, message, nil)
        end

        def self.bad(errors)
          new(:bad, nil, Array(errors))
        end
      end

      module_function

      def run(cli, pattern, header:, summary_extra: [])
        files = expand(pattern)
        if files.empty?
          cli.say "No files found matching pattern: #{pattern}", :red
          exit 1
        end

        cli.say "#{header} #{files.size} file(s)...", :blue

        ok_count = 0
        bad_count = 0

        files.each do |file|
          $stdout.print "  #{File.basename(file)}... "
          result = yield file
          if result.status == :ok
            label = result.message ? "✅ #{result.message}" : "✅"
            cli.say label, :green
            ok_count += 1
          else
            cli.say "❌ INVALID", :red
            bad_count += 1
            Array(result.errors).each { |e| cli.say "    #{e}", :red }
          end
        end

        print_summary(cli, files.size, ok_count, bad_count, summary_extra)
        exit(bad_count.positive? ? 1 : 0)
      end

      def expand(pattern)
        Dir.glob(pattern).select { |f| File.file?(f) && f.match?(/\.ya?ml\z/i) }.sort
      end

      def print_summary(cli, total, ok_count, bad_count, summary_extra)
        cli.say "\n📊 Summary:", :blue
        cli.say "  Total: #{total}", :blue
        cli.say "  Success: #{ok_count}, Failed: #{bad_count}",
                bad_count.positive? ? :red : :green
        rate = total.zero? ? 0 : ((ok_count.to_f / total) * 100).round(1)
        cli.say "  Success rate: #{rate}%", :blue
        summary_extra.each { |label, value| cli.say "  #{label}: #{value}", :blue }
      end
    end

    package_name "edoxen"

    # --- Decision-side commands -----------------------------------------

    desc "validate YAML_FILE_PATTERN",
         "Validate Decision YAML file(s) against schema/edoxen.yaml and the model."

    def validate(pattern)
      run_validate(PROFILES.fetch(:decisions), pattern)
    end

    desc "normalize YAML_FILE_PATTERN",
         "Round-trip Decision YAML file(s) through the model (--output DIR or --inplace)."

    option :output, type: :string, desc: "Output directory for normalized files"
    option :inplace, type: :boolean, desc: "Modify files in place (no backup)"

    def normalize(pattern)
      run_normalize(PROFILES.fetch(:decisions), pattern)
    end

    # --- Meeting-side commands ------------------------------------------

    desc "validate-meetings YAML_FILE_PATTERN",
         "Validate Meeting/Agenda YAML file(s) against schema/meeting.yaml."

    def validate_meetings(pattern)
      run_validate(PROFILES.fetch(:meetings), pattern)
    end

    desc "normalize-meetings YAML_FILE_PATTERN",
         "Round-trip Meeting YAML file(s) through the model (--output DIR or --inplace)."

    option :output, type: :string, desc: "Output directory for normalized files"
    option :inplace, type: :boolean, desc: "Modify files in place (no backup)"

    def normalize_meetings(pattern)
      run_normalize(PROFILES.fetch(:meetings), pattern)
    end

    # --- Reference-data lookups -----------------------------------------

    desc "unlocode CODE", "Resolve a UN/LOCODE via the canonical registry."

    def unlocode(code)
      entry = Edoxen::ReferenceData.find_unlocode(code)
      if entry.nil?
        say "No entry for #{code.upcase} in the UN/LOCODE registry.", :red
        exit 1
      end

      say "UN/LOCODE:  #{entry.code}", :blue
      say "  Name:      #{entry.name}"
      say "  Country:   #{entry.country}"
      say "  Subdiv:    #{entry.subdivision}" if entry.subdivision
      coords = entry.coordinates
      say "  Coords:    #{coords}" if coords
      funcs = entry.function_codes.compact
      say "  Functions: #{funcs.join(", ")}" unless funcs.empty?
    end

    desc "iata CODE", "Resolve an IATA airport/city code via the canonical registry."

    def iata(code)
      entry = Edoxen::ReferenceData.find_iata(code)
      if entry.nil?
        say "No entry for #{code.upcase} in the IATA registry.", :red
        exit 1
      end

      say "IATA:       #{entry.code}", :blue
      say "  Name:      #{entry.name}"
      say "  Country:   #{entry.country_iso2}"
    end

    private

    def run_validate(profile, pattern)
      validator = SchemaValidator.new(profile.schema_path)
      Batch.run(self, pattern, header: "🔍 Validating #{profile.name}") do |file|
        schema_errors = validator.validate_file(file)
        model_errors = collect_model_errors(profile, file)
        if schema_errors.empty? && model_errors.empty?
          Batch::Result.ok("VALID")
        else
          Batch::Result.bad((schema_errors + model_errors).map(&:to_clickable_format))
        end
      end
    end

    def run_normalize(profile, pattern)
      unless valid_normalize_options?
        say normalize_options_error, :red
        exit 1
      end

      summary_extra = [
        ["  Output directory", options[:output]],
        ["  Mode", options[:inplace] ? "in place" : "--output"]
      ].compact

      Batch.run(self, pattern, header: "🔄 Normalizing #{profile.name}", summary_extra: summary_extra) do |file|
        Batch::Result.ok(normalize_file(profile, file))
      rescue StandardError => e
        Batch::Result.bad(["#{file}:1:1: #{e.message}"])
      end
    end

    def collect_model_errors(profile, file)
      profile.load(File.read(file))
      []
    rescue StandardError => e
      [Edoxen::ValidationError.new(
        file: file, line: 1, column: 1,
        message_text: "Model parsing failed: #{e.message}",
        source: Edoxen::ValidationError::SOURCE_MODEL
      )]
    end

    def normalize_file(profile, file)
      original = File.read(file)
      schema_comment = extract_yaml_language_server_comment(original)
      normalized = profile.load(original).to_yaml
      write_normalized(file, normalized, schema_comment)
    rescue StandardError => e
      raise "#{file}: #{e.message}"
    end

    def write_normalized(file, normalized, schema_comment)
      normalized = "#{schema_comment}\n#{normalized}" if schema_comment

      if options[:inplace]
        File.write(file, normalized)
        "NORMALIZED"
      else
        out = File.join(options[:output], File.basename(file))
        FileUtils.mkdir_p(File.dirname(out))
        File.write(out, normalized)
        "NORMALIZED → #{out}"
      end
    end

    def extract_yaml_language_server_comment(content)
      lines = content.split("\n").first(5)
      lines.find { |l| l.strip.match?(/\A#\s*yaml-language-server:\s*\$schema=/) }&.rstrip
    end

    def valid_normalize_options?
      return false if options[:output] && options[:inplace]
      return false unless options[:output] || options[:inplace]

      true
    end

    def normalize_options_error
      if options[:output] && options[:inplace]
        "Error: Cannot use both --output and --inplace options"
      else
        "Error: Must specify either --output or --inplace option"
      end
    end
  end
end
