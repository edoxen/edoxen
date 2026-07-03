# frozen_string_literal: true

require "spec_helper"

# Schema <-> Ruby enum sync for the Meeting side. Parallel to
# schema_enum_sync_spec.rb. Asserts every $defs/<EnumName>.enum array
# in schema/meeting.yaml equals the matching Edoxen::Enums::* frozen array.
MEETING_SCHEMA_ENUM_BINDINGS = {
  "MeetingType" => :MEETING_TYPE,
  "MeetingStatus" => :MEETING_STATUS,
  "AgendaStatus" => :AGENDA_STATUS,
  "AgendaItemKind" => :AGENDA_ITEM_KIND,
  "AgendaItemOutcome" => :AGENDA_ITEM_OUTCOME,
  "HostType" => :HOST_TYPE,
  "MeetingRelationType" => :MEETING_RELATION_TYPE,
  "SourceUrlKind" => :SOURCE_URL_KIND,
  "ParticipationStatus" => :PARTICIPATION_STATUS,
  "VoteType" => :VOTE_TYPE
}.freeze

RSpec.describe "Schema <-> Ruby meeting enum sync" do
  let(:defs) { YAML.safe_load(File.read("schema/meeting.yaml")).fetch("$defs") }

  MEETING_SCHEMA_ENUM_BINDINGS.each do |enum_name, ruby_const|
    it "keeps $defs/#{enum_name} equal to Edoxen::Enums::#{ruby_const}" do
      entry = defs.fetch(enum_name)
      expect(entry["type"]).to eq("string")
      schema_values = Array(entry["enum"])
      ruby_values = Edoxen::Enums.const_get(ruby_const)
      expect(schema_values).to match_array(ruby_values)
    end
  end
end
