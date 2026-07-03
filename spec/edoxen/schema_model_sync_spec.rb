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
  Edoxen::PhysicalVenue => "PhysicalVenue",
  Edoxen::VirtualVenue => "VirtualVenue",
  Edoxen::RecurrenceByDay => "RecurrenceByDay",
  Edoxen::Recurrence => "Recurrence",
  Edoxen::Officer => "Officer",
  Edoxen::ComponentLocalization => "ComponentLocalization",
  Edoxen::MeetingComponent => "MeetingComponent",
  Edoxen::MeetingSeries => "MeetingSeries"
}.freeze

RSpec.describe "Schema <-> Ruby model shape sync" do
  let(:defs) { YAML.safe_load(File.read("schema/edoxen.yaml")).fetch("$defs") }

  SCHEMA_MODEL_BINDINGS.each do |ruby_class, schema_name|
    describe "#{ruby_class.name} <-> $defs/#{schema_name}" do
      let(:schema_def) { defs.fetch(schema_name) }
      let(:schema_props) { schema_def["properties"] || {} }
      let(:schema_required) { schema_def.fetch("required", []) }

      it "declares a $defs/#{schema_name} block" do
        expect(defs).to have_key(schema_name)
      end

      it "has every Ruby attribute present as a schema property or required entry" do
        ruby_attr_names = ruby_class.attributes.keys.map(&:to_s)
        allowed = schema_props.keys + schema_required

        missing = ruby_attr_names - allowed
        expect(missing).to be_empty,
                           "#{ruby_class} declares #{missing.inspect} with no matching property " \
                           "or required entry in $defs/#{schema_name}"
      end

      it "declares Ruby collection attributes as type: array in the schema" do
        ruby_class.attributes.each do |name, attr|
          next unless attr.collection?

          schema_prop = schema_props[name.to_s]
          next unless schema_prop # absent props are flagged by the previous example

          actual = schema_prop["type"]
          expect(actual).to eq("array"),
                            "#{ruby_class}##{name} is collection: true but " \
                            "$defs/#{schema_name}/#{name} is type=#{actual.inspect}, not 'array'"
        end
      end

      it "has every schema property (or required entry) backed by a Ruby attribute" do
        schema_names = schema_props.keys + schema_required
        ruby_attr_names = ruby_class.attributes.keys.map(&:to_s)

        orphan = schema_names - ruby_attr_names
        expect(orphan).to be_empty,
                          "$defs/#{schema_name} declares #{orphan.inspect} with no matching attribute on #{ruby_class}"
      end
    end
  end
end
