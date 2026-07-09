# frozen_string_literal: true

require "spec_helper"

# Mapping from each schema `$defs` enum-name to the Ruby constant in
# `lib/edoxen/enums.rb`. Declared outside the describe block so rubocop
# doesn't flag it as `Lint/ConstantDefinitionInBlock`.
SCHEMA_ENUM_BINDINGS = {
  "ApprovalType" => :APPROVAL_TYPE,
  "ApprovalDegree" => :APPROVAL_DEGREE,
  "DecisionKind" => :DECISION_KIND,
  "DecisionKindCanonical" => :DECISION_KIND_CANONICAL,
  "DecisionStatus" => :DECISION_STATUS,
  "DecisionDateType" => :DECISION_DATE_TYPE,
  "DecisionRelationType" => :DECISION_RELATION_TYPE,
  "MotionStatus" => :MOTION_STATUS,
  "VotingStatus" => :VOTING_STATUS,
  "VotingMethod" => :VOTING_METHOD,
  "VotingOutcome" => :VOTING_OUTCOME,
  "TopicStatus" => :TOPIC_STATUS,
  "VenueKind" => :VENUE_KIND,
  "VirtualFeature" => :VIRTUAL_FEATURE,
  "Visibility" => :VISIBILITY,
  "AttendanceRole" => :ATTENDANCE_ROLE,
  "AttendanceResponse" => :ATTENDANCE_RESPONSE,
  "ComponentKind" => :COMPONENT_KIND,
  "ComponentKindCanonical" => :COMPONENT_KIND_CANONICAL,
  "OfficerRole" => :OFFICER_ROLE,
  "RecurrenceFreq" => :RECURRENCE_FREQ,
  "UrlKind" => :URL_KIND,
  "SourceUrlKind" => :SOURCE_URL_KIND,
  "HostType" => :HOST_TYPE,
  "VoteType" => :VOTE_TYPE,
  "ContactMethodKind" => :CONTACT_METHOD_KIND,
  "ContactIdentifierKind" => :CONTACT_IDENTIFIER_KIND
}.freeze

# Schema <-> Ruby enum sync. The schema in `schema/edoxen.yaml` MUST agree,
# value-for-value, with the constants in `Edoxen::Enums`. Adding a value in
# one without the other is a future-bug; this spec fails at runtime.
RSpec.describe "Schema <-> Ruby enum sync" do
  let(:schema) { YAML.safe_load_file("schema/edoxen.yaml") }
  let(:defs) { schema.fetch("$defs") }

  SCHEMA_ENUM_BINDINGS.each do |enum_name, ruby_const|
    describe "##{enum_name}" do
      it "matches Edoxen::Enums::#{ruby_const} value-for-value" do
        schema_entry = defs.fetch(enum_name)
        expect(schema_entry["type"]).to eq("string"),
                                        "$defs/#{enum_name} must declare type=string"
        schema_values = Array(schema_entry["enum"])
        ruby_values = Edoxen::Enums.const_get(ruby_const)
        expect(schema_values).to match_array(ruby_values),
                                 "schema $defs/#{enum_name} (=#{schema_values.inspect}) " \
                                 "differs from Edoxen::Enums::#{ruby_const} (=#{ruby_values.inspect}); " \
                                 "update both in the same commit."
      end
    end
  end

  it "every enum declared in the schema is bound to a Ruby constant" do
    schema_enum_defs = defs.keys.select do |name|
      defs[name]["type"] == "string" && defs[name]["enum"].is_a?(Array)
    end
    schema_enum_defs.each do |enum_name|
      unless SCHEMA_ENUM_BINDINGS.key?(enum_name)
        raise "$defs/#{enum_name} is declared in schema/edoxen.yaml but has no Ruby binding"
      end

      expect(SCHEMA_ENUM_BINDINGS).to have_key(enum_name)
    end
  end

  describe "intentionally permissive enums (schema open, Ruby closed)" do
    # `ActionType` and `ConsiderationType` are deliberately permissive
    # on the schema side (`type: string`, no `enum:` array) so adopters
    # can use body-specific verbs ("scopes", "directs", "establishes")
    # outside the canonical advisory set. The Ruby model closes them
    # with `values: Enums::ACTION_TYPE` / `CONSIDERATION_TYPE` so
    # canonical-set consumers see drift immediately at construction
    # time. This spec pins both halves of the asymmetry so neither
    # side silently regresses.

    %w[ActionType ConsiderationType].each do |enum_name|
      it "$defs/#{enum_name} is type:string with NO enum: array" do
        entry = defs.fetch(enum_name)
        expect(entry["type"]).to eq("string")
        expect(entry).not_to have_key("enum"),
                             "$defs/#{enum_name} gained an `enum:` array — " \
                             "this closes the permissive contract that lets " \
                             "adopters use body-specific verbs. If the closure " \
                             "is intentional, update this spec and the README."
      end
    end

    it "Edoxen::Action#type carries values: Enums::ACTION_TYPE" do
      attr = Edoxen::Action.attributes[:type]
      expect(attr.options[:values]).to eq(Edoxen::Enums::ACTION_TYPE)
    end

    it "Edoxen::Consideration#type carries values: Enums::CONSIDERATION_TYPE" do
      attr = Edoxen::Consideration.attributes[:type]
      expect(attr.options[:values]).to eq(Edoxen::Enums::CONSIDERATION_TYPE)
    end
  end
end
