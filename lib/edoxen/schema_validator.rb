# frozen_string_literal: true

require "json_schemer"
require "yaml"

module Edoxen
  # Validates Edoxen YAML files against `schema/edoxen.yaml`.
  #
  # The SchemaValidator is intentionally small and only owns one concern:
  # JSON-Schema validation with line-accurate error reporting. It does not
  # touch the Ruby model — CLI layers SchemaValidator and
  # `ResolutionCollection.from_yaml` to catch both schema-level violations
  # (additionalProperties, required, enum) and structural issues
  # (numeric/date coercion, missing nested classes) the schema can't express.
  #
  # Line tracking is built from indentation heuristics over the source text.
  # That's a deliberate trade-off: a 30-line heuristic versus introducing a
  # full line-tracking YAML parser dependency, in exchange for error reports
  # that are accurate on real-world 2-space-indented fixture files (which is
  # all we use). The lookup is OCP-compliant (longest-prefix match — no
  # hard-coded path shapes) so adding new collection fields never requires
  # touching this class.
  class SchemaValidator
    # Back-compat alias. The canonical type is Edoxen::ValidationError;
    # this constant lets existing callers keep writing
    # `SchemaValidator::ValidationError` after the unification.
    ValidationError = Edoxen::ValidationError

    def initialize(schema_path = default_schema_path)
      @schema_path = schema_path
      @schemer = load_schemer(schema_path)
    end

    # Validate a YAML file. Returns an array of Edoxen::ValidationError
    # (empty = ok).
    def validate_file(file_path)
      validate_content(File.read(file_path), file_path)
    rescue Errno::ENOENT
      [ValidationError.new(
        file: file_path, line: 1, column: 1,
        message_text: "File not found", source: Edoxen::ValidationError::SOURCE_SCHEMA
      )]
    end

    # Validate a YAML string. Returns an array of Edoxen::ValidationError.
    def validate_content(content, file_path)
      data = normalize_dates(YAML.safe_load(content, permitted_classes: [Date, Time]))
      line_map = LineMap.build(content)

      @schemer.validate(data).to_a.map do |err|
        pointer = err.fetch("data_pointer", "")
        message = format_message(err)
        line, column = LineMap.locate(pointer, line_map)
        ValidationError.new(
          file: file_path, line: line, column: column,
          message_text: message, pointer: pointer,
          source: Edoxen::ValidationError::SOURCE_SCHEMA
        )
      end
    rescue Psych::SyntaxError => e
      [ValidationError.new(
        file: file_path, line: e.line || 1, column: e.column || 1,
        message_text: "YAML syntax error: #{e.problem}",
        source: Edoxen::ValidationError::SOURCE_SYNTAX
      )]
    end

    private

    def default_schema_path
      File.expand_path("../../schema/edoxen.yaml", __dir__)
    end

    def load_schemer(path)
      JSONSchemer.schema(YAML.safe_load_file(path, permitted_classes: [Date, Time]))
    end

    # Coerce Date/Time instances back to ISO strings before handing the
    # data to json_schemer — the schema declares them as `type: string,
    # format: date` because that's also the wire form. Walking the hash
    # here keeps the gem OCP-compliant (no json_schemer plugin/tweak).
    def normalize_dates(value)
      case value
      when Date, Time then value.iso8601
      when Hash then value.transform_values { |v| normalize_dates(v) }
      when Array then value.map { |v| normalize_dates(v) }
      else value
      end
    end

    def format_message(err)
      type = err["type"]
      details = err["details"] || {}
      pointer = err["data_pointer"].to_s
      case type
      when "required"
        missing = Array(details["missing_keys"])
        if missing.size == 1
          "object is missing required property: #{missing.first}"
        else
          "object is missing required properties: #{missing.join(", ")}"
        end
      when "additionalProperties"
        extra = Array(details["extra_keys"])
        case extra.size
        when 0 then "object has disallowed additional properties"
        when 1 then "object property '#{extra.first}' is a disallowed additional property"
        else "object properties #{extra.map { |k| "'#{k}'" }.join(", ")} are disallowed additional properties"
        end
      when "enum"
        vals = Array(details["valid_values"])
        enums = vals.empty? ? "(see schema)" : vals.join(", ")
        "value #{details["value"].inspect} is not one of: #{enums}"
      when "type"
        expected = Array(details["expected_types"])
        "value is not #{expected.empty? ? "the expected type" : expected.join(" or ")}"
      when "pattern"
        "value #{details["value"].inspect} does not match pattern #{details["pattern"].inspect}"
      when "minItems"
        "array has fewer than #{details["minimum"]} items"
      when "maxItems"
        "array has more than #{details["maximum"]} items"
      else
        err["error"] || "validation failed"
      end
    end

    # Builds a {path => line_no} map for a YAML source. The path is the
    # JSON-Schema-style pointer: "/metadata", "/resolutions/0/title", etc.
    # This is a tag-class is allocated freely — no `instance_variable_set`
    # ever crosses another object's boundary.
    module LineMap
      module_function

      # @return [Hash{String => Integer}]
      def build(content)
        map = {}
        stack = []
        array_counter = Hash.new(-1)
        array_path_for = {}

        content.each_line.with_index(1) do |raw, line_no|
          line = raw.chomp
          stripped = line.strip
          next if stripped.empty? || stripped.start_with?("#") || stripped == "---"

          indent = line.index(/\S/) || 0
          level = indent / 2
          stack = stack.first(level)

          if stripped.start_with?("- ")
            parent = stack.empty? ? "" : "/#{stack.join("/")}"
            parent_key = parent.empty? ? parent : parent.dup
            array_counter[parent_key] = -1 unless array_counter.key?(parent_key)
            array_counter[parent_key] += 1
            array_index = array_counter[parent_key]
            array_path = "#{parent}/#{array_index}"
            map[array_path] = line_no

            remainder = stripped[2..].to_s.strip
            if remainder.match(/\A(.+?):(\s|$)/)
              key = Regexp.last_match(1).strip.gsub(/["']/, "")
              map["#{array_path}/#{key}"] = line_no
              stack = stack.first(level) + [array_index.to_s, key]
            else
              stack = stack.first(level) + [array_index.to_s]
            end
          elsif (md = stripped.match(/\A(.+?):(\s|$)/))
            key = md[1].strip.gsub(/["']/, "")
            stack = stack.first(level) + [key]
            full = "/#{stack.join("/")}"
            map[full] = line_no
            array_counter.delete_if { |p, _| p.start_with?(full) }
          end
        end
        map
      end

      # @return [Array(Integer, Integer)] [line, column] for the given
      #   JSON-Schema data pointer. Picks the longest prefix in the line map
      #   — pure longest-match, no knowledge of specific path shapes.
      def locate(pointer, line_map)
        pointer = pointer.to_s
        return [1, 1] if pointer.empty?

        match_key = line_map.keys
                            .select { |path| pointer.start_with?(path) || path.start_with?(pointer) }
                            .max_by(&:length)

        match_key ? [line_map[match_key], 1] : [1, 1]
      end
    end
  end
end
