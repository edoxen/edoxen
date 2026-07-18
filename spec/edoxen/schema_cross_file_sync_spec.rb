# frozen_string_literal: true

require "spec_helper"

# Cross-schema DRY spec. `schema/edoxen.yaml` and `schema/meeting.yaml`
# intentionally re-declare a shared set of $defs (entities + enums) so
# each file is self-contained for validators that only load one. The
# per-file sync specs (`schema_enum_sync_spec`, `schema_meeting_enum_sync_spec`,
# `schema_model_sync_spec`, `schema_meeting_model_sync_spec`) only check
# Ruby ↔ one schema file. This spec catches the third drift dimension:
# schema file ↔ schema file.
#
# Every name listed below MUST be byte-for-byte equal across the two
# files (deep equality on the parsed YAML hash). Adding a new shared
# $def? Add its name to SHARED_NAMES in the same commit — the
# discovery spec at the bottom will fail if you forget.

SHARED_NAMES = %w[
  StructuredIdentifier SourceUrl SourceUrlKind
  Person HostRef HostType VoteRecord Reference
  TopicDocument TopicAsset Topic
  Venue RecurrenceByDay Recurrence
  ExtensionAttribute MeetingExtension BodyVocabularyEntry
  Officer MeetingComponent MeetingSeries
  EntityRef
  Contact ContactMethod ContactIdentifier Name
  AttendanceRole AttendanceResponse VoteType TopicStatus
  VenueKind VirtualFeature Visibility ComponentKind OfficerRole RecurrenceFreq
  ContactMethodKind ContactIdentifierKind
  LocalizedString LocalizedName
  Statement StatementKind Declaration DeclarationKind DateTimeRange Body BodyRegister
].freeze

RSpec.describe "Cross-schema shared $defs sync (edoxen.yaml ↔ meeting.yaml)" do
  let(:edoxen_defs)   { YAML.safe_load_file("schema/edoxen.yaml").fetch("$defs") }
  let(:meeting_defs)  { YAML.safe_load_file("schema/meeting.yaml").fetch("$defs") }

  SHARED_NAMES.each do |name|
    describe "$defs/#{name}" do
      it "is declared in both schema files" do
        expect(edoxen_defs).to have_key(name),
                               "$defs/#{name} is missing from schema/edoxen.yaml"
        expect(meeting_defs).to have_key(name),
                                "$defs/#{name} is missing from schema/meeting.yaml"
      end

      it "is byte-for-byte equal across both files" do
        skip "$defs/#{name} missing from one file (see above)" unless edoxen_defs.key?(name) && meeting_defs.key?(name)
        expect(meeting_defs[name]).to eq(edoxen_defs[name]),
                                      "$defs/#{name} in meeting.yaml diverges from edoxen.yaml — " \
                                      "update both in the same commit (or extract to a shared file)."
      end
    end
  end

  # Discovery: catch any *future* shared $def that hasn't been added to
  # SHARED_NAMES yet. Walks every $defs entry in edoxen.yaml, finds the
  # ones also declared in meeting.yaml, and asserts they're listed.
  it "every $def duplicated across both files is listed in SHARED_NAMES" do
    duplicated = edoxen_defs.keys & meeting_defs.keys
    unlisted = duplicated - SHARED_NAMES
    expect(unlisted).to be_empty,
                        "These $defs are duplicated across schema/edoxen.yaml and " \
                        "schema/meeting.yaml but not listed in SHARED_NAMES: #{unlisted.inspect}. " \
                        "Add them so the cross-file sync spec catches future drift."
  end
end
