# frozen_string_literal: true

module Edoxen
  # Base class for any Edoxen-level error. Reserved for raise-on-failure paths.
  class Error < StandardError; end

  # Unified validation failure shape. Produced by both:
  #   * SchemaValidator — JSON-Schema violations and YAML syntax errors
  #     carry source: :schema (or :syntax for Psych::SyntaxError).
  #   * DecisionCollection.from_yaml rescues in the CLI — model parse
  #     failures carry source: :model.
  #
  # One type at the seam means callers (CLI, future renderers, tests)
  # handle one shape instead of N.
  class ValidationError < Error
    SOURCE_SCHEMA = :schema
    SOURCE_MODEL = :model
    SOURCE_SYNTAX = :syntax

    attr_reader :file, :line, :column, :pointer, :message_text, :source

    def initialize(file:, line:, column:, message_text:, pointer: "", source: SOURCE_SCHEMA)
      @file = file
      @line = line
      @column = column
      @pointer = pointer.to_s
      @message_text = message_text
      @source = source
      super(to_clickable_format)
    end

    def to_clickable_format
      suffix = @pointer.empty? ? "" : " at `#{@pointer}`"
      "#{@file}:#{@line}:#{@column}: #{@message_text}#{suffix}"
    end
  end
end
