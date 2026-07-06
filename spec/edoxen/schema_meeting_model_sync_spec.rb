# frozen_string_literal: true

require "spec_helper"

# Schema <-> Ruby model shape sync for the Meeting side. Parallel to
# schema_model_sync_spec.rb. Walks every Ruby model class on the
# Meeting side and asserts the matching $defs/<ClassName> block in
# schema/meeting.yaml declares the same property names and collection
# flags.
MEETING_SCHEMA_MODEL_BINDINGS = {
  Edoxen::DateRange => "DateRange",
  Edoxen::Person => "Person",
  Edoxen::HostRef => "HostRef",
  Edoxen::Deadline => "Deadline",
  Edoxen::Reference => "Reference",
  Edoxen::AgendaItem => "AgendaItem",
  Edoxen::Agenda => "Agenda",
  Edoxen::Attendance => "Attendance",
  Edoxen::VoteRecord => "VoteRecord",
  Edoxen::MinutesSection => "MinutesSection",
  Edoxen::Minutes => "Minutes",
  Edoxen::MeetingRelation => "MeetingRelation",
  Edoxen::MeetingLocalization => "MeetingLocalization",
  Edoxen::Meeting => "Meeting",
  Edoxen::MeetingCollectionMetadata => "MeetingCollectionMetadata",
  Edoxen::MeetingCollection => "MeetingCollection"
}.freeze

RSpec.describe "Schema <-> Ruby meeting model shape sync" do
  let(:defs) { YAML.safe_load_file("schema/meeting.yaml").fetch("$defs") }

  MEETING_SCHEMA_MODEL_BINDINGS.each do |ruby_class, schema_name|
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
          next unless schema_prop

          actual = schema_prop["type"]
          expect(actual).to eq("array"),
                            "#{ruby_class}##{name} is collection: true but " \
                            "$defs/#{schema_name}/#{name} is type=#{actual.inspect}, not 'array'"
        end
      end

      it "has every schema property (or required entry) backed by a Ruby attribute" do
        schema_names_set = schema_props.keys + schema_required
        ruby_attr_names = ruby_class.attributes.keys.map(&:to_s)

        orphan = schema_names_set - ruby_attr_names
        expect(orphan).to be_empty,
                          "$defs/#{schema_name} declares #{orphan.inspect} with no matching attribute on #{ruby_class}"
      end
    end
  end
end
