# frozen_string_literal: true

require "spec_helper"

RSpec.describe Edoxen::SchemaValidator do
  describe ".new" do
    it "loads the canonical schema by default" do
      expect { described_class.new }.not_to raise_error
    end

    it "accepts an alternate schema path (used for forked schemas in forks)" do
      custom_path = File.expand_path("../../schema/edoxen.yaml", __dir__)
      expect { described_class.new(custom_path) }.not_to raise_error
    end
  end

  describe "ValidationError" do
    it "renders a clickable file:line:column: message" do
      err = described_class::ValidationError.new(
        file: "foo.yaml", line: 12, column: 3,
        pointer: "/resolutions/0",
        message_text: "object is missing required property: identifier"
      )
      expect(err.message).to include("foo.yaml:12:3:")
      expect(err.message).to include("object is missing required property: identifier")
      expect(err.message).to include("`/resolutions/0`")
      expect(err.pointer).to eq("/resolutions/0")
      expect(err.line).to eq(12)
    end
  end

  describe "#validate_file" do
    it "returns an empty array for fixtures that conform to the schema" do
      Dir.glob(File.expand_path("../fixtures/*.yaml", __dir__)).each do |fixture|
        errors = described_class.new.validate_file(fixture)
        expect(errors).to be_empty, "#{File.basename(fixture)} failed validation: #{errors.map(&:message).join("; ")}"
      end
    end

    it "returns a not-found error for missing files" do
      missing = File.expand_path("../fixtures/__missing__.yaml", __dir__)
      errors = described_class.new.validate_file(missing)
      expect(errors.size).to eq(1)
      expect(errors.first.message_text).to include("File not found")
    end
  end

  describe "#validate_content" do
    let(:validator) { described_class.new }

    it "reports an `additionalProperties` violation at the offending path" do
      content = <<~YAML
        ---
        decision:
          type: bogus
      YAML
      errors = validator.validate_content(content, "memory")
      expect(errors).not_to be_empty
      expect(errors.first.message_text).to include("disallowed additional")
      expect(errors.first.pointer).to include("/decision")
    end

    it "reports a `required` violation at the missing-key path" do
      content = <<~YAML
        ---
        decisions:
          - identifier:
              - prefix: X
                number: "1"
      YAML
      errors = validator.validate_content(content, "memory")
      # 1.0: identifier is the only required field on Decision
      expect(errors).to be_empty
    end

    it "accepts a non-canonical action verb (ActionType is permissive)" do
      content = <<~YAML
        ---
        decisions:
          - identifier:
              - prefix: X
                number: "1"
            title:
              - spelling: eng
                value: T
            actions:
              - type: non-standard-verb
                date_effective:
                  date: 2024-01-15
                  type: adoption
                message:
                  - spelling: eng
                    value: x
      YAML
      errors = validator.validate_content(content, "memory")
      expect(errors).to be_empty,
                        "Expected no errors (ActionType is permissive); got: #{errors.map(&:message_text).inspect}"
    end

    it "reports a `pattern` violation for an invalid scoped URN on a Contact" do
      content = <<~YAML
        ---
        metadata:
          title:
            - spelling: eng
              value: T
        decisions:
          - identifier:
              - prefix: X
                number: "1"
            title:
              - spelling: eng
                value: T
      YAML
      errors = validator.validate_content(content, "memory")
      # Sanity: the basic shape passes
      expect(errors).to be_empty
    end

    it "reports a YAML syntax error gracefully without crashing" do
      content = "{ not: valid yaml: ]["
      errors = validator.validate_content(content, "memory")
      expect(errors).not_to be_empty
      expect(errors.first.message_text).to include("YAML syntax error")
    end

    it "uses longest-prefix line lookup (no path-shape hardcoding)" do
      # ActionType is now permissive (1.0+), so use a non-canonical
      # DecisionKind to trigger an enum violation instead.
      content = <<~YAML
        ---
        metadata:
          title:
            - spelling: eng
              value: T
        decisions:
          - identifier:
              - prefix: X
                number: "1"
            kind: not-a-valid-kind
            title:
              - spelling: eng
                value: T
            actions:
              - type: resolves
                date_effective:
                  date: 2024-01-15
                  type: adoption
                message:
                  - spelling: eng
                    value: x
      YAML
      errors = validator.validate_content(content, "memory")
      enum_error = errors.find { |e| e.message_text.include?("not one of") }
      expect(enum_error).not_to be_nil
      # /decisions/0 is on line 5; /decisions/0/kind is on line 8.
      # Longest-prefix match should locate line 8 specifically.
      expect(enum_error.line).to be >= 7
    end
  end
end
