# frozen_string_literal: true

require "spec_helper"
require "pathname"

# Gem schema ↔ model canonical schema sync.
#
# The model repo at `../edoxen-model/` ships canonical JSON Schemas at
# `schema/decision-collection.yaml` and `schema/meeting.yaml`. Per
# that repo's `schema/README.md`:
#
#   These are the single source of truth — the Ruby gem at
#   edoxen/edoxen mirrors them.
#
# The gem ships mirror copies at `schema/edoxen.yaml` (mirrors
# `decision-collection.yaml`) and `schema/meeting.yaml` (mirrors
# `meeting.yaml`). This spec enforces byte-for-byte equality of every
# `$defs` entry across the two pairs so future edits don't drift
# silently.
#
# Skipped gracefully when the model repo isn't checked out (same
# pattern as `lutaml_ruby_sync_spec`).

MODEL_ROOT = Pathname.new(__dir__).parent.parent.parent.join("edoxen-model")
MODEL_DECISION_SCHEMA = MODEL_ROOT.join("schema", "decision-collection.yaml")
MODEL_MEETING_SCHEMA  = MODEL_ROOT.join("schema", "meeting.yaml")

# Resolve at load time (plain constants, not `let` — `let` is unavailable
# in the example-group scope where we declare sub-describes).
if MODEL_ROOT.exist?
  GEM_DECISION_DEFS   = YAML.safe_load_file("schema/edoxen.yaml").fetch("$defs")
  GEM_MEETING_DEFS    = YAML.safe_load_file("schema/meeting.yaml").fetch("$defs")
  MODEL_DECISION_DEFS = YAML.safe_load_file(MODEL_DECISION_SCHEMA).fetch("$defs")
  MODEL_MEETING_DEFS  = YAML.safe_load_file(MODEL_MEETING_SCHEMA).fetch("$defs")
  DECISION_NAMES = (GEM_DECISION_DEFS.keys + MODEL_DECISION_DEFS.keys).uniq.sort
  MEETING_NAMES  = (GEM_MEETING_DEFS.keys  + MODEL_MEETING_DEFS.keys).uniq.sort
else
  GEM_DECISION_DEFS = GEM_MEETING_DEFS = MODEL_DECISION_DEFS = MODEL_MEETING_DEFS = {}.freeze
  DECISION_NAMES = MEETING_NAMES = [].freeze
end

RSpec.describe "Gem schema ↔ model canonical schema sync" do
  next pending "edoxen-model repo not found at #{MODEL_ROOT}; skipping schema sync" unless MODEL_ROOT.exist?

  describe "schema/edoxen.yaml ↔ edoxen-model/schema/decision-collection.yaml" do
    DECISION_NAMES.each do |name|
      it "$defs/#{name} matches" do
        gem_def   = GEM_DECISION_DEFS[name]
        model_def = MODEL_DECISION_DEFS[name]

        expect(gem_def).not_to be_nil,
                               "$defs/#{name} is in the model's decision-collection.yaml " \
                               "but not in the gem's schema/edoxen.yaml"
        expect(model_def).not_to be_nil,
                                 "$defs/#{name} is in the gem's schema/edoxen.yaml " \
                                 "but not in the model's schema/decision-collection.yaml"

        expect(gem_def).to eq(model_def),
                           "$defs/#{name} drifted between gem and model. " \
                           "Per edoxen-model/schema/README.md, the model is the source " \
                           "of truth — update both in the same PR (or push gem " \
                           "improvements up to the model)."
      end
    end
  end

  describe "schema/meeting.yaml ↔ edoxen-model/schema/meeting.yaml" do
    MEETING_NAMES.each do |name|
      it "$defs/#{name} matches" do
        gem_def   = GEM_MEETING_DEFS[name]
        model_def = MODEL_MEETING_DEFS[name]

        expect(gem_def).not_to be_nil,
                               "$defs/#{name} is in the model's meeting.yaml " \
                               "but not in the gem's schema/meeting.yaml"
        expect(model_def).not_to be_nil,
                                 "$defs/#{name} is in the gem's schema/meeting.yaml " \
                                 "but not in the model's schema/meeting.yaml"

        expect(gem_def).to eq(model_def),
                           "$defs/#{name} drifted between gem and model. " \
                           "Per edoxen-model/schema/README.md, the model is the source " \
                           "of truth — update both in the same PR (or push gem " \
                           "improvements up to the model)."
      end
    end
  end
end
