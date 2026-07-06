# frozen_string_literal: true

require "spec_helper"
require "pathname"

# LutaML ↔ Ruby sync.
#
# Walks every `class` declaration in `edoxen-model/models/*.lutaml` and
# asserts the matching `Edoxen::*` Ruby class declares the same attribute
# names (camelCase lutaml ↔ snake_case Ruby) and the same collection
# flags. Closes the root-cause gap left by the v2.0 drift audit
# (`edoxen-model/TODO.refactor/20-post-v2-gem-drift.md`).
#
# Skips:
#   - Files with the `// Superseded by` marker (Location, ScheduleItem,
#     ScheduleItemLocalization — vestigial; gem deleted the Ruby side).
#   - The `_*.lutaml.deprecated` files (SubjectBody; same reason).
#   - `enum` blocks (covered by schema_enum_sync_spec transitively).
#   - The whole suite, with a per-example skip message, when the
#     sibling `edoxen-model/` repo isn't checked out.

# Resolve at load time (plain constants, not `let` — `let` is unavailable
# in the example-group scope where we declare sub-describes).
MODELS_DIR = Pathname.new(__dir__).parent.parent.parent.join("edoxen-model", "models")
LUTAML_FILES = Dir.glob(MODELS_DIR.join("*.lutaml"))

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

SKIP_MESSAGE = "edoxen-model repo not checked out at #{MODELS_DIR}; skipping LutaML sync".freeze

# Keyed on directory existence, not glob emptiness: a checkout that IS
# present but yields no *.lutaml files is a broken path/glob, and the
# sanity check below must fail loudly rather than be skipped.
RSpec.describe "LutaML <-> Ruby sync", skip: MODELS_DIR.directory? ? false : SKIP_MESSAGE do
  it "found at least one lutaml file (sanity check)" do
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
