# frozen_string_literal: true

require "spec_helper"

# Walks every Ruby model class and asserts the schema's matching
# `$defs/<ClassName>` block declares the same property names and
# collection flags. Catches drift that the enum-only sync spec misses
# (e.g. adding `attribute :foo` to a model without adding `foo` to the
# schema's properties — the schema would reject the new field as an
# `additionalProperties` violation at fixture-validation time, which
# is far too late).
#
# The enum-list invariant is covered by `schema_enum_sync_spec.rb`.
# This spec covers the *shape* invariant.

# Mapping from each Ruby model class to its `$defs` name in the schema.
SCHEMA_MODEL_BINDINGS = {
  Edoxen::StructuredIdentifier => "StructuredIdentifier",
  Edoxen::EntityRef => "EntityRef",
  Edoxen::MeetingIdentifier => "MeetingIdentifier",
  Edoxen::DecisionDate => "DecisionDate",
  Edoxen::Action => "Action",
  Edoxen::Approval => "Approval",
  Edoxen::Consideration => "Consideration",
  Edoxen::Localization => "Localization",
  Edoxen::SourceUrl => "SourceUrl",
  Edoxen::Url => "Url",
  Edoxen::DecisionRelation => "DecisionRelation",
  Edoxen::Decision => "Decision",
  Edoxen::DecisionMetadata => "DecisionMetadata",
  Edoxen::Motion => "Motion",
  Edoxen::VotingCounts => "VotingCounts",
  Edoxen::Voting => "Voting",
  Edoxen::TopicDocument => "TopicDocument",
  Edoxen::TopicAsset => "TopicAsset",
  Edoxen::Topic => "Topic",
  Edoxen::ExtensionAttribute => "ExtensionAttribute",
  Edoxen::MeetingExtension => "MeetingExtension",
  Edoxen::Venue => "Venue",
  Edoxen::RecurrenceByDay => "RecurrenceByDay",
  Edoxen::Recurrence => "Recurrence",
  Edoxen::Officer => "Officer",
  Edoxen::ComponentLocalization => "ComponentLocalization",
  Edoxen::MeetingComponent => "MeetingComponent",
  Edoxen::MeetingSeries => "MeetingSeries",
  Edoxen::ContactMethod => "ContactMethod",
  Edoxen::ContactIdentifier => "ContactIdentifier",
  Edoxen::Name => "Name",
  Edoxen::Contact => "Contact"
}.freeze

RSpec.describe "Schema <-> Ruby model shape sync" do
  let(:defs) { YAML.safe_load_file("schema/edoxen.yaml").fetch("$defs") }

  # ExtensionAttribute uses camelCase wire names (intValue, floatValue,
  # ...) via lutaml-model's `map "intValue", to: :integer_value`. The
  # Ruby attribute names are snake_case; the schema property names are
  # the wire names. Skip the strict name-equality check for this one
  # class — its attribute-to-property mapping is intentionally lossy
  # on the name axis.
  WIRE_NAME_RENAMES = {
    "Edoxen::ExtensionAttribute" => {
      "integer_value" => "intValue",
      "float_value" => "floatValue",
      "boolean_value" => "booleanValue",
      "date_value" => "dateValue",
      "date_time_value" => "dateTimeValue",
    },
  }.freeze

  SCHEMA_MODEL_BINDINGS.each do |ruby_class, schema_name|
    describe "#{ruby_class.name} <-> $defs/#{schema_name}" do
      let(:schema_def) { defs.fetch(schema_name) }
      let(:schema_props) { schema_def["properties"] || {} }
      let(:schema_required) { schema_def.fetch("required", []) }
      let(:renames) { WIRE_NAME_RENAMES[ruby_class.name] || {} }

      it "declares a $defs/#{schema_name} block" do
        expect(defs).to have_key(schema_name)
      end

      it "has every Ruby attribute present as a schema property or required entry" do
        ruby_attr_names = ruby_class.attributes.keys.map(&:to_s)
        allowed = schema_props.keys + schema_required
        # Apply wire-name renames so the comparison lands on the
        # camelCase schema property name where applicable.
        mapped = ruby_attr_names.map { |n| renames.fetch(n, n) }

        missing = mapped - allowed
        expect(missing).to be_empty,
                           "#{ruby_class} declares #{missing.inspect} with no matching property " \
                           "or required entry in $defs/#{schema_name}"
      end

      it "declares Ruby collection attributes as type: array in the schema" do
        ruby_class.attributes.each do |name, attr|
          next unless attr.collection?

          wire_name = renames.fetch(name.to_s, name.to_s)
          schema_prop = schema_props[wire_name]
          next unless schema_prop # absent props are flagged by the previous example

          actual = schema_prop["type"]
          expect(actual).to eq("array"),
                            "#{ruby_class}##{name} is collection: true but " \
                            "$defs/#{schema_name}/#{wire_name} is type=#{actual.inspect}, not 'array'"
        end
      end

      it "has every schema property (or required entry) backed by a Ruby attribute" do
        schema_names = schema_props.keys + schema_required
        ruby_attr_names = ruby_class.attributes.keys.map(&:to_s)
        # Reverse the rename so the schema name lands on a Ruby attr.
        reverse_renames = renames.invert
        mapped = schema_names.map { |n| reverse_renames.fetch(n, n) }

        orphan = mapped - ruby_attr_names
        expect(orphan).to be_empty,
                          "$defs/#{schema_name} declares #{orphan.inspect} with no matching attribute on #{ruby_class}"
      end
    end
  end
end
