# frozen_string_literal: true

require "thor"
require "fileutils"

module Edoxen
  class Cli < Thor
    # Deep module behind the per-command interface. Owns the
    # expand/sort/empty/header/loop/tally/summary/exit scaffold so
    # `validate` and `normalize` collapse to per-file blocks.
    #
    # Commands call `Batch.run(self, pattern, header:)` and yield a block
    # that returns `Result.ok(message)` or `Result.bad(errors)`. The
    # batch runner prints progress, tallies, prints the summary, and
    # exits with the right code.
    #
    # In-process; no adapter. The seam is the call site in each
    # command method — internal to the CLI.
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

      # Run a batch over every YAML file matching `pattern`.
      #
      # Yields each file path to the caller's block. Block must return
      # a Batch::Result. The batch runner handles progress output,
      # tallies, summary, and the exit code.
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

    desc "validate YAML_FILE_PATTERN",
         "Validate one or more Edoxen YAML files against the schema and the model."

    def validate(pattern)
      validator = SchemaValidator.new
      Batch.run(self, pattern, header: "🔍 Validating") do |file|
        schema_errors = validator.validate_file(file)
        model_errors = collect_model_errors(file)
        if schema_errors.empty? && model_errors.empty?
          Batch::Result.ok("VALID")
        else
          errors = (schema_errors + model_errors).map(&:to_clickable_format)
          Batch::Result.bad(errors)
        end
      end
    end

    desc "normalize YAML_FILE_PATTERN",
         "Round-trip YAML file(s) through the Edoxen model (--output DIR or --inplace)."

    option :output, type: :string, desc: "Output directory for normalized files"
    option :inplace, type: :boolean, desc: "Modify files in place (no backup)"

    def normalize(pattern)
      unless valid_normalize_options?
        say normalize_options_error, :red
        exit 1
      end

      summary_extra = [
        ["  Output directory", options[:output]],
        ["  Mode", options[:inplace] ? "in place" : "--output"]
      ].compact

      Batch.run(self, pattern, header: "🔄 Normalizing", summary_extra: summary_extra) do |file|
        Batch::Result.ok(normalize_file(file))
      rescue StandardError => e
        Batch::Result.bad(["#{file}:1:1: #{e.message}"])
      end
    end

    desc "validate-meetings YAML_FILE_PATTERN",
         "Validate Meeting/Agenda YAML file(s) against schema/meeting.yaml."

    def validate_meetings(pattern)
      validator = SchemaValidator.new(meeting_schema_path)
      Batch.run(self, pattern, header: "🔍 Validating meetings") do |file|
        schema_errors = validator.validate_file(file)
        model_errors = collect_meeting_model_errors(file)
        if schema_errors.empty? && model_errors.empty?
          Batch::Result.ok("VALID")
        else
          errors = (schema_errors + model_errors).map(&:to_clickable_format)
          Batch::Result.bad(errors)
        end
      end
    end

    desc "normalize-meetings YAML_FILE_PATTERN",
         "Round-trip Meeting YAML file(s) through the model (--output DIR or --inplace)."

    option :output, type: :string, desc: "Output directory for normalized files"
    option :inplace, type: :boolean, desc: "Modify files in place (no backup)"

    def normalize_meetings(pattern)
      unless valid_normalize_options?
        say normalize_options_error, :red
        exit 1
      end

      summary_extra = [
        ["  Output directory", options[:output]],
        ["  Mode", options[:inplace] ? "in place" : "--output"]
      ].compact

      Batch.run(self, pattern, header: "🔄 Normalizing meetings", summary_extra: summary_extra) do |file|
        Batch::Result.ok(normalize_meeting_file(file))
      rescue StandardError => e
        Batch::Result.bad(["#{file}:1:1: #{e.message}"])
      end
    end

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
      funcs = entry.functions.compact.map(&:to_s)
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
      say "  Country:   #{entry.country}"
    end

    private

    def meeting_schema_path
      File.expand_path("../../schema/meeting.yaml", __dir__)
    end

    def collect_model_errors(file)
      DecisionCollection.from_yaml(File.read(file))
      []
    rescue StandardError => e
      [Edoxen::ValidationError.new(
        file: file, line: 1, column: 1,
        message_text: "Model parsing failed: #{e.message}",
        source: Edoxen::ValidationError::SOURCE_MODEL
      )]
    end

    def collect_meeting_model_errors(file)
      load_meeting_document(file)
      []
    rescue StandardError => e
      [Edoxen::ValidationError.new(
        file: file, line: 1, column: 1,
        message_text: "Meeting model parsing failed: #{e.message}",
        source: Edoxen::ValidationError::SOURCE_MODEL
      )]
    end

    # A meeting YAML may be either a single Meeting or a
    # MeetingCollection. Detect by the presence of a top-level
    # `meetings:` key and parse accordingly. Returns whichever
    # model object was successfully constructed.
    def load_meeting_document(file)
      data = YAML.safe_load(File.read(file), permitted_classes: [Date, Time])
      if data.is_a?(Hash) && data.key?("meetings")
        MeetingCollection.from_yaml(File.read(file))
      else
        Meeting.from_yaml(File.read(file))
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

    # Writes the normalized YAML either to the original file (--inplace)
    # or under the --output directory. Returns a one-line status message
    # for the batch runner to print after the ✅.
    def normalize_file(file)
      original = File.read(file)
      yaml_language_server_comment = extract_yaml_language_server_comment(original)
      normalized = DecisionCollection.from_yaml(original).to_yaml
      write_normalized(file, normalized, yaml_language_server_comment)
    end

    def normalize_meeting_file(file)
      yaml_language_server_comment = extract_yaml_language_server_comment(File.read(file))
      normalized = load_meeting_document(file).to_yaml
      write_normalized(file, normalized, yaml_language_server_comment)
    end

    def write_normalized(file, normalized, yaml_language_server_comment)
      normalized = "#{yaml_language_server_comment}\n#{normalized}" if yaml_language_server_comment

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
  end
end
