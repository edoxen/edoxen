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

    module_function

    # Parse a single .lutaml source string into an array of LutamlClass.
    # Enum blocks are skipped (they are covered by the schema-enum-sync
    # spec; the lutaml-ruby sync is concerned only with classes).
    def parse(source)
      classes = []
      state = :top
      current = nil

      source.each_line.with_index(1) do |raw, _lineno|
        line = raw.strip
        next if line.empty? || line.start_with?("//") || line.start_with?("#")
        next if line == "---"

        case state
        when :top
          if (md = line.match(/\Aclass\s+([A-Z]\w*)\s*(?:<\s*([A-Z]\w*))?\s*\{/))
            current = LutamlClass.new(name: md[1], parent: md[2], attrs: [])
            state = :class_body
          elsif line.start_with?("enum ")
            state = :enum_body
          end
        when :class_body
          if line.start_with?("}")
            classes << current
            current = nil
            state = :top
          elsif (md = line.match(/\A([a-z]\w*):\s*([A-Za-z_]\w*)(\[[^\]]+\])?/))
            current.attrs << LutamlAttr.new(
              name: md[1],
              type: md[2],
              collection: !md[3].nil?
            )
          end
        when :enum_body
          state = :top if line.start_with?("}")
        end
      end

      classes
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
