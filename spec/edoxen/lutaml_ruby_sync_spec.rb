# frozen_string_literal: true

require "spec_helper"
require "pathname"
require "set"

# LutaML ↔ Ruby sync.
#
# Walks every `class` declaration in `edoxen-model/models/*.lutaml` and
# asserts the matching `Edoxen::*` Ruby class declares the same attribute
# names (camelCase lutaml ↔ snake_case Ruby), the same collection flags,
# and the same types. Closes the root-cause gap left by the 1.0 drift
# audit (`edoxen-model/TODO.refactor/50-post-v2-gem-drift-closed.md`).
#
# Skips:
#   - Files with the `// Superseded by` marker (Location, ScheduleItem,
#     ScheduleItemLocalization — vestigial; gem deleted the Ruby side).
#   - The `_*.lutaml.deprecated` files (SubjectBody; same reason).
#   - `enum` blocks (covered by schema_enum_sync_spec transitively).
#   - The whole suite, with a single pending message, when the
#     sibling `edoxen-model/` repo isn't checked out.

# Resolve at load time (plain constants, not `let` — `let` is unavailable
# in the example-group scope where we declare sub-describes).
MODELS_DIR = Pathname.new(__dir__).parent.parent.parent.join("edoxen-model", "models")
LUTAML_FILES = Dir.glob(MODELS_DIR.join("*.lutaml"))

# LutaML primitive type name → lutaml-model Ruby primitive class.
# Class-reference types (e.g. `DecisionDate`) are passed through as
# `Edoxen::<Name>` directly.
LUTAML_PRIMITIVE_RUBY = {
  "String" => Lutaml::Model::Type::String,
  "Integer" => Lutaml::Model::Type::Integer,
  "Float" => Lutaml::Model::Type::Float,
  "Boolean" => Lutaml::Model::Type::Boolean,
  "Date" => Lutaml::Model::Type::Date,
  "DateTime" => Lutaml::Model::Type::DateTime,
  "Time" => Lutaml::Model::Type::Time
}.freeze

# Pre-compute (basename, source, lutaml_classes, superseded?) for every
# file. Filtering happens at iteration time so the per-class describe
# blocks are static and match one-to-one with the model files.
PARSED_FILES = LUTAML_FILES.map do |path|
  basename = File.basename(path)
  source = File.read(path)
  # `// Superseded by` is the project's marker for vestigial files kept
  # for traceability (Location, ScheduleItem, ScheduleItemLocalization).
  superseded = source.match?(%r{\A\s*//}) && source.include?("Superseded by")
  classes = superseded ? [] : Edoxen::LutamlParser.parse(source).classes
  enums   = superseded ? [] : Edoxen::LutamlParser.parse(source).enums
  { path: path, basename: basename, source: source,
    superseded: superseded, classes: classes, enums: enums }
end.freeze

# Index by class name so the spec can walk the inheritance chain on the
# lutaml side (the parser emits parent names but does not resolve them).
LUTAML_BY_NAME = PARSED_FILES.flat_map { |f| f[:classes] }
                             .to_h { |c| [c.name, c] }
                             .freeze

SUPERSEDED_FILES = PARSED_FILES.select { |f| f[:superseded] }.map { |f| f[:basename] }

# All enum names declared in the LutaML files. The gem models enum-typed
# attributes as `:string, values: Enums::X` (a constrained primitive),
# not as class-typed attributes — so when the LutaML type is an enum
# name, the type-equality check would always drift. The enum-value sync
# spec already enforces that the canonical set matches; here we just
# skip the type axis.
LUTAML_ENUM_NAMES = PARSED_FILES.flat_map { |f| f[:enums].map(&:name) }.uniq.to_set.freeze

# Resolve a LutaML type name to the expected Ruby type object:
#   - Primitive ("String", "Integer", ...) → lutaml-model Type class.
#   - Enum name → `:enum` sentinel (skip — covered by enum sync).
#   - Anything else → the matching `Edoxen::<Name>` class constant.
# Returns `nil` if the resolution fails (the spec example will then
# report the missing class).
def expected_ruby_type_for(lutaml_type_name)
  return :enum if LUTAML_ENUM_NAMES.include?(lutaml_type_name)
  return LUTAML_PRIMITIVE_RUBY[lutaml_type_name] if LUTAML_PRIMITIVE_RUBY.key?(lutaml_type_name)

  Edoxen.const_get(lutaml_type_name)
rescue NameError
  nil
end

RSpec.describe "LutaML <-> Ruby sync" do
  pending "edoxen-model repo not found at #{MODELS_DIR}; skipping LutaML sync" if LUTAML_FILES.empty?

  it "found at least one lutaml file (sanity check)" do
    if LUTAML_FILES.empty?
      skip "edoxen-model repo not found at #{MODELS_DIR}; CI must checkout edoxen-model as a sibling"
    end
    expect(LUTAML_FILES).not_to be_empty, "expected models/*.lutaml to be non-empty"
  end

  it "did not skip too many files as superseded" do
    expect(SUPERSEDED_FILES.size).to be <= 4,
                                     "Expected at most 4 superseded files (Location, ScheduleItem, " \
                                     "ScheduleItemLocalization, ResolutionType); found " \
                                     "#{SUPERSEDED_FILES.size}: #{SUPERSEDED_FILES.inspect}. " \
                                     "Re-check the // Superseded by marker detection."
  end

  PARSED_FILES.each do |parsed|
    next if parsed[:superseded]

    parsed[:classes].each do |lutaml_class|
      describe "#{parsed[:basename]} :: #{lutaml_class.name}" do
        let(:ruby_class) do
          Edoxen.const_get(lutaml_class.name)
        rescue NameError => e
          raise NameError,
                "No Ruby class for LutaML class #{lutaml_class.name} " \
                "(file: #{parsed[:basename]}): #{e.message}"
        end

        it "exists as an Edoxen Ruby class" do
          expect(ruby_class).to be_a(Class)
          expect(ruby_class).to be < Lutaml::Model::Serializable
        end

        it "has matching inheritance (lutaml parent ↔ Ruby superclass)" do
          next unless lutaml_class.parent

          expect(ruby_class.superclass.name).to eq("Edoxen::#{lutaml_class.parent}"),
                                                "#{lutaml_class.name} should inherit from #{lutaml_class.parent} " \
                                                "(got #{ruby_class.superclass.inspect})"
        end

        it "has matching attribute names (camelCase lutaml ↔ snake_case Ruby)" do
          # Walk the lutaml inheritance chain — subclasses inherit parent
          # attributes (the gem's flat Venue is a wire-shape choice; the
          # lutaml uses conceptual inheritance which the spec must honour).
          lutaml_full_attrs = lutaml_class.attrs.dup
          cursor = lutaml_class
          while cursor.parent && LUTAML_BY_NAME[cursor.parent]
            cursor = LUTAML_BY_NAME[cursor.parent]
            lutaml_full_attrs.concat(cursor.attrs)
          end
          expected_ruby_names = lutaml_full_attrs.map(&:snake_name).uniq

          ruby_attr_names = ruby_class.attributes.keys.map(&:to_s)

          missing_on_ruby = expected_ruby_names - ruby_attr_names
          extra_on_ruby = ruby_attr_names - expected_ruby_names

          expect(missing_on_ruby).to be_empty,
                                     "LutaML declares #{missing_on_ruby.inspect} on #{lutaml_class.name} " \
                                     "(incl. inherited) but Ruby #{ruby_class.name} does not " \
                                     "(file: #{parsed[:basename]})"
          expect(extra_on_ruby).to be_empty,
                                   "Ruby #{ruby_class.name} declares #{extra_on_ruby.inspect} " \
                                   "but LutaML #{lutaml_class.name} (incl. inherited) does not " \
                                   "(file: #{parsed[:basename]})"
        end

        it "has matching collection flags" do
          lutaml_full_attrs = lutaml_class.attrs.dup
          cursor = lutaml_class
          while cursor.parent && LUTAML_BY_NAME[cursor.parent]
            cursor = LUTAML_BY_NAME[cursor.parent]
            lutaml_full_attrs.concat(cursor.attrs)
          end

          lutaml_full_attrs.each do |attr|
            ruby_attr = ruby_class.attributes[attr.snake_name.to_sym]
            next unless ruby_attr

            expect(ruby_attr.collection?).to eq(attr.collection),
                                             "Attribute #{lutaml_class.name}.#{attr.name} (Ruby :#{attr.snake_name}) " \
                                             "cardinality mismatch: LutaML collection=#{attr.collection}, " \
                                             "Ruby collection=#{ruby_attr.collection?} (file: #{parsed[:basename]})"
          end
        end

        it "has matching attribute types" do
          # Same inheritance walk as the name-sync example — subclass
          # attrs inherit from the parent on the LutaML side.
          lutaml_full_attrs = lutaml_class.attrs.dup
          cursor = lutaml_class
          while cursor.parent && LUTAML_BY_NAME[cursor.parent]
            cursor = LUTAML_BY_NAME[cursor.parent]
            lutaml_full_attrs.concat(cursor.attrs)
          end

          lutaml_full_attrs.each do |attr|
            ruby_attr = ruby_class.attributes[attr.snake_name.to_sym]
            next unless ruby_attr

            expected_ruby_type = expected_ruby_type_for(attr.type)
            # Enum-typed attributes are modelled as :string, values: X on
            # the Ruby side; the value-list equality is enforced by the
            # enum sync examples further down. Skip the type axis here.
            next if expected_ruby_type == :enum

            actual = ruby_attr.type

            # lutaml-model returns either a Type::<Primitive> class or
            # the referenced model class itself. Compare by identity.
            expect(actual).to eq(expected_ruby_type),
                              "Attribute #{lutaml_class.name}.#{attr.name} type mismatch: " \
                              "LutaML #{attr.type.inspect} ↔ Ruby #{actual.inspect} " \
                              "(file: #{parsed[:basename]})."
          end
        end
      end
    end

    # Enum sync (TODO 22): for every `enum FooBar { ... }` block, find
    # the matching `Edoxen::Enums::FOO_BAR` constant and assert value-
    # for-value equality. Closes the last uncovered link between the
    # lutaml files and the gem.
    parsed[:enums].each do |lutaml_enum|
      describe "#{parsed[:basename]} :: #{lutaml_enum.name} (enum)" do
        let(:ruby_const_name) { lutaml_enum.ruby_constant.to_sym }

        let(:ruby_values) do
          raise NameError, "Edoxen::Enums::#{lutaml_enum.ruby_constant} is not defined" \
            unless Edoxen::Enums.const_defined?(ruby_const_name)

          Edoxen::Enums.const_get(ruby_const_name)
        end

        it "has a matching Edoxen::Enums constant" do
          expect(Edoxen::Enums).to be_const_defined(ruby_const_name),
                                   "No Edoxen::Enums::#{lutaml_enum.ruby_constant} for LutaML enum " \
                                   "#{lutaml_enum.name} (file: #{parsed[:basename]})"
        end

        it "has matching values (order-independent)" do
          expect(ruby_values).to match_array(lutaml_enum.items),
                                 "LutaML enum #{lutaml_enum.name} (=#{lutaml_enum.items.inspect}) " \
                                 "differs from Edoxen::Enums::#{lutaml_enum.ruby_constant} " \
                                 "(=#{ruby_values.inspect}); update both in the same commit " \
                                 "(file: #{parsed[:basename]})"
        end

        it "is frozen on the Ruby side" do
          # Every Edoxen::Enums::* constant should be frozen — the
          # schema-enum-sync spec asserts this in detail, but a quick
          # check here catches accidental regressions.
          expect(ruby_values).to be_frozen,
                                 "Edoxen::Enums::#{lutaml_enum.ruby_constant} should be frozen"
        end
      end
    end
  end
end
