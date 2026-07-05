# frozen_string_literal: true

require "strscan"

module Edoxen
  module LutamlParser
    # Lightweight line-based parser for the project's LutaML files.
    # Covers only the small regular subset the edoxen-model repo uses:
    #
    #   class ClassName {                  (or: class ClassName < Parent {)
    #     attrName: Type
    #     attrName: Type[N..M]
    #     attrName: Type[1..*]
    #     ...
    #   }
    #
    #   enum EnumName {
    #     value1
    #     value2
    #   }
    #
    # Anything more complex (nested generics, multiline type params,
    # comments that aren't on their own line) is out of scope — file an
    # issue and extend the parser deliberately.
    #
    # Lives under spec/support because it is exercised only by the
    # lutaml ↔ Ruby sync spec. Not autoloaded by lib/edoxen.rb.

    LutamlAttr = Struct.new(:name, :type, :collection, keyword_init: true) do
      def snake_name
        LutamlParser.snakeify(name)
      end
    end

    LutamlClass = Struct.new(:name, :parent, :attrs, keyword_init: true) do
      def attr_names
        attrs.map(&:name)
      end

      def snake_attr_names
        attrs.map(&:snake_name)
      end
    end

    LutamlEnum = Struct.new(:name, :values, keyword_init: true) do
      # CamelCase enum name → SCREAMING_SNAKE_CASE Ruby constant.
      # Used by the sync spec to resolve the matching `Edoxen::Enums::*`.
      def ruby_constant
        LutamlParser.snakeify(name).upcase
      end
    end

    ParseResult = Struct.new(:classes, :enums, keyword_init: true) do
      # Back-compat: callers that did `LutamlParser.parse(source)` and
      # expected an array of LutamlClass still work.
      def to_ary
        classes
      end
    end

    module_function

    # Parse a single .lutaml source string into a ParseResult
    # (classes: + enums:). Destructuring via `to_ary` keeps the older
    # array-of-classes return shape working for callers that haven't
    # been updated.
    def parse(source)
      classes = []
      enums = []
      state = :top
      current_class = nil
      current_enum = nil
      # Local depth counter for `{ ... }` blocks under enum values.
      # Reset when entering :enum_definition; lives on the call frame,
      # not on the module, so concurrent calls don't share state.
      enum_def_depth = 0

      source.each_line.with_index(1) do |raw, _lineno|
        line = raw.strip
        next if line.empty? || line.start_with?("//") || line.start_with?("#")
        next if line == "---"

        case state
        when :top
          if (md = line.match(/\Aclass\s+([A-Z]\w*)\s*(?:<\s*([A-Z]\w*))?\s*\{/))
            current_class = LutamlClass.new(name: md[1], parent: md[2], attrs: [])
            state = :class_body
          elsif (md = line.match(/\Aenum\s+([A-Z]\w*)\s*\{/))
            current_enum = LutamlEnum.new(name: md[1], values: [])
            state = :enum_body
          end
        when :class_body
          if line.start_with?("}")
            classes << current_class
            current_class = nil
            state = :top
          elsif (md = line.match(/\A([a-z]\w*):\s*([A-Za-z_]\w*)(\[[^\]]+\])?/))
            current_class.attrs << LutamlAttr.new(
              name: md[1],
              type: md[2],
              collection: !md[3].nil?
            )
          end
        when :enum_body
          if line.start_with?("}")
            enums << current_enum
            current_enum = nil
            state = :top
          elsif (md = line.match(/\A([a-z][\w-]*)\s*\{/))
            # value with a nested definition block — record the value,
            # then track depth to skip everything inside the block.
            current_enum.values << md[1]
            enum_def_depth = 1
            state = :enum_definition
          elsif (md = line.match(/\A([a-z][\w-]*)\z/))
            current_enum.values << md[1]
          end
        when :enum_definition
          # Inside a `{ ... }` block under an enum value (typically a
          # `definition { ... }` sub-block). Track brace depth and pop
          # back to the enum body when balanced.
          enum_def_depth += line.count("{") - line.count("}")
          state = :enum_body if enum_def_depth <= 0
        end
      end

      ParseResult.new(classes: classes, enums: enums)
    end

    def parse_file(path)
      parse(File.read(path))
    end

    # camelCase → snake_case. Mirrors the gem's
    # scripts/camel_to_snake_samples.rb helper; kept here so the spec
    # has no runtime dependency on a scripts/ directory.
    def snakeify(name)
      return name unless name.is_a?(String)

      name
        .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .downcase
    end
  end
end
