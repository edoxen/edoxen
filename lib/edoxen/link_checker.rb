# frozen_string_literal: true

module Edoxen
  # Walks a directory tree of Meeting, MeetingSeries, and
  # DecisionCollection YAML files and asserts that every cross-document
  # URN link resolves.
  #
  # Invariants enforced:
  #
  #   * Every Meeting#urn (if set) is referenced by exactly one
  #     DecisionCollection#metadata.meeting_urn (if the collection
  #     exists in the scanned directory).
  #   * Every DecisionCollection#metadata.meeting_urn (if set)
  #     resolves to a Meeting whose urn matches.
  #
  # Recognised top-level document kinds (per canonical 1.0 schemas):
  #
  #   * DecisionCollection — `{ metadata:, decisions: [] }`.
  #   * MeetingCollection — `{ metadata:, meetings: [] }` (its members
  #     are walked individually so each Meeting#urn enters the index).
  #   * Meeting — `{ identifier: [...], type: ... }`.
  #   * MeetingSeries — `{ identifier: [...], meeting_refs: [...] }`
  #     (or any hash with `recurrence` + `identifier`).
  #
  # Use from CLI / scripts via the public `check` class method. Returns
  # an array of `LinkError` records (empty = ok).
  #
  # All file IO is read-only. No edits to the YAMLs.
  class LinkChecker
    LinkError = Struct.new(:file, :pointer, :urn, :kind) do
      def message
        "#{file}: #{pointer} references #{urn} (#{kind})"
      end
    end

    # Walk `dir` (recursive scan of *.yaml and *.yml), classify each
    # file as a Meeting / MeetingSeries / MeetingCollection /
    # DecisionCollection, and assert every cross-document URN resolves.
    #
    # @return [Array<LinkError>] empty when all links resolve.
    def self.check(dir)
      new(dir).check
    end

    def initialize(dir)
      @dir = dir
      @meetings_by_urn = {} # urn → file
      @collections_by_meeting_urn = {} # meeting_urn → file
    end

    def check
      require "yaml"

      Dir.glob(File.join(@dir, "**", "*.{yaml,yml}")).each do |file|
        data = safe_load_yaml(file)
        next unless data.is_a?(Hash)

        if collection_shape?(data)
          meeting_urn = data.dig("metadata", "meeting_urn")
          @collections_by_meeting_urn[meeting_urn] = file if meeting_urn
        elsif meeting_collection_shape?(data)
          Array(data["meetings"]).each do |meeting|
            register_meeting(meeting, file) if meeting.is_a?(Hash)
          end
        elsif meeting_shape?(data) || meeting_series_shape?(data)
          register_meeting(data, file)
        end
      end

      errors = []

      # DecisionCollection → Meeting
      @collections_by_meeting_urn.each do |meeting_urn, file|
        next if @meetings_by_urn.key?(meeting_urn)

        errors << LinkError.new(file, "metadata.meeting_urn", meeting_urn, "no matching Meeting")
      end

      errors
    end

    private

    def register_meeting(data, file)
      urn = data["urn"]
      @meetings_by_urn[urn] = file if urn
    end

    def safe_load_yaml(file)
      YAML.safe_load_file(file)
    rescue Psych::SyntaxError, ArgumentError
      nil
    end

    # DecisionCollection — the canonical root carries `decisions: []`.
    def collection_shape?(data)
      data["decisions"].is_a?(Array)
    end

    # MeetingCollection — `{ meetings: [...] }`.
    def meeting_collection_shape?(data)
      data["meetings"].is_a?(Array)
    end

    # Meeting — flat top-level hash with identifier[] + type.
    def meeting_shape?(data)
      data["identifier"].is_a?(Array) && data.key?("type")
    end

    # MeetingSeries — flat top-level hash with identifier[] and either
    # `meeting_refs` (canonical) or `recurrence` (series rule).
    def meeting_series_shape?(data)
      data["identifier"].is_a?(Array) &&
        (data.key?("meeting_refs") || data.key?("recurrence"))
    end
  end
end
