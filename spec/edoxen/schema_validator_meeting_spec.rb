# frozen_string_literal: true

require "spec_helper"

# SchemaValidator constructed with the meeting schema path. Mirrors
# spec/edoxen/schema_validator_spec.rb but against schema/meeting.yaml.
MEETING_FIXTURES_DIR = File.expand_path("../fixtures/meetings", __dir__)
MEETING_SCHEMA_PATH  = File.expand_path("../../schema/meeting.yaml", __dir__)

RSpec.describe Edoxen::SchemaValidator do
  let(:validator) { described_class.new(MEETING_SCHEMA_PATH) }

  describe ".new with meeting schema path" do
    it "loads schema/meeting.yaml without raising" do
      expect { described_class.new(MEETING_SCHEMA_PATH) }.not_to raise_error
    end
  end

  describe "#validate_file against meeting fixtures" do
    Dir.glob(File.join(MEETING_FIXTURES_DIR, "*.yaml")).each do |fixture|
      it "returns no errors for #{File.basename(fixture)}" do
        errors = validator.validate_file(fixture)
        expect(errors).to be_empty,
                          "#{File.basename(fixture)} failed: #{errors.map(&:message).join("; ")}"
      end
    end
  end

  describe "#validate_content error reporting" do
    it "reports an enum violation for an invalid MeetingType" do
      content = YAML.dump(
        "identifier" => [{ "prefix" => "X", "number" => "1" }],
        "type" => "not-a-real-type"
      )
      errors = validator.validate_content(content, "memory")
      expect(errors).not_to be_empty
      # oneOf produces errors from both branches; assert at least one
      # is the enum violation from the Meeting branch.
      expect(errors.any? { |e| e.message_text.match?(/not one of|enum/i) })
        .to be(true), "expected an enum error; got: #{errors.map(&:message_text).inspect}"
    end

    it "reports a required violation when identifier is missing" do
      content = YAML.dump("type" => "plenary")
      errors = validator.validate_content(content, "memory")
      expect(errors).not_to be_empty
      expect(errors.any? { |e| e.message_text.match?(/missing required|identifier/i) })
        .to be(true)
    end

    it "reports a pattern violation for an invalid scoped URN on Contact" do
      content = YAML.dump(
        "identifier" => [{ "prefix" => "X", "number" => "1" }],
        "type" => "plenary",
        "contact" => { "urn" => "not-a-valid-urn" }
      )
      errors = validator.validate_content(content, "memory")
      expect(errors).not_to be_empty
      expect(errors.any? { |e| e.message_text.match?(/pattern|not one of|does not match/i) })
        .to be(true)
    end
  end
end
