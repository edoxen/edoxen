# frozen_string_literal: true

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

    # `items` (not `values` or `entries`) avoids overriding Struct's
    # built-in `values` and `entries` methods.
    LutamlEnum = Struct.new(:name, :items, keyword_init: true) do
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

    # Mutable per-call state. Kept in a Struct (not on the module) so
    # concurrent parse calls don't share state.
    ParserState = Struct.new(:state, :current_class, :current_enum, :enum_def_depth, keyword_init: true) do
      def initialize
        super(state: :top, current_class: nil, current_enum: nil, enum_def_depth: 0)
      end
    end

    module_function

    # Parse a single .lutaml source string into a ParseResult
    # (classes: + enums:). Destructuring via `to_ary` keeps the older
    # array-of-classes return shape working for callers that haven't
    # been updated.
    def parse(source)
      ctx = ParserState.new
      classes = []
      enums = []

      source.each_line do |raw|
        line = raw.strip
        next if skip_line?(line)

        handle(line, ctx, classes, enums)
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

    # --- Line filtering -------------------------------------------------

    def skip_line?(line)
      line.empty? || line.start_with?("//") || line.start_with?("#") || line == "---"
    end

    # --- State dispatch -------------------------------------------------

    def handle(line, ctx, classes, enums)
      case ctx.state
      when :top then handle_top(line, ctx)
      when :class_body then handle_class_body(line, ctx, classes)
      when :enum_body then handle_enum_body(line, ctx, enums)
      when :enum_definition then handle_enum_definition(line, ctx)
      end
    end

    def handle_top(line, ctx)
      if (md = line.match(/\Aclass\s+([A-Z]\w*)\s*(?:<\s*([A-Z]\w*))?\s*\{/))
        ctx.current_class = LutamlClass.new(name: md[1], parent: md[2], attrs: [])
        ctx.state = :class_body
      elsif (md = line.match(/\Aenum\s+([A-Z]\w*)\s*\{/))
        ctx.current_enum = LutamlEnum.new(name: md[1], items: [])
        ctx.state = :enum_body
      end
    end

    def handle_class_body(line, ctx, classes)
      if line.start_with?("}")
        classes << ctx.current_class
        ctx.current_class = nil
        ctx.state = :top
      elsif (md = line.match(/\A([a-z]\w*):\s*([A-Za-z_]\w*)(\[[^\]]+\])?/))
        ctx.current_class.attrs << LutamlAttr.new(
          name: md[1],
          type: md[2],
          collection: !md[3].nil?
        )
      end
    end

    def handle_enum_body(line, ctx, enums)
      if line.start_with?("}")
        enums << ctx.current_enum
        ctx.current_enum = nil
        ctx.state = :top
      elsif (md = line.match(/\A([a-z][\w-]*)\s*\{/))
        ctx.current_enum.items << md[1]
        ctx.enum_def_depth = 1
        ctx.state = :enum_definition
      elsif (md = line.match(/\A([a-z][\w-]*)\z/))
        ctx.current_enum.items << md[1]
      end
    end

    def handle_enum_definition(line, ctx)
      ctx.enum_def_depth += line.count("{") - line.count("}")
      ctx.state = :enum_body if ctx.enum_def_depth <= 0
    end
  end
end
