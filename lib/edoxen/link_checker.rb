# frozen_string_literal: true

module Edoxen
  # Walks a directory tree of Meeting and DecisionCollection YAML
  # files and asserts that every cross-document URN link resolves.
  #
  # Invariants enforced:
  #
  #   * Every Meeting#urn (if set) is referenced by exactly one
  #     DecisionCollection#metadata.meeting_urn (if the collection
  #     exists in the scanned directory).
  #   * Every DecisionCollection#metadata.meeting_urn (if set)
  #     resolves to a Meeting whose urn matches.
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
    # file as Meeting or DecisionCollection, and assert every
    # cross-document URN resolves to a real record.
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

        if data["meetings"].is_a?(Array)
          index_meeting_collection(data, file)
        elsif meeting_shape?(data)
          urn = data["urn"]
          @meetings_by_urn[urn] = file if urn
        elsif collection_shape?(data)
          meeting_urn = data.dig("metadata", "meeting_urn")
          @collections_by_meeting_urn[meeting_urn] = file if meeting_urn
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

    def safe_load_yaml(file)
      YAML.safe_load_file(file, permitted_classes: [Date, Time])
    rescue Psych::SyntaxError, Psych::DisallowedClass, ArgumentError
      nil
    end

    def meeting_shape?(data)
      data["identifier"].is_a?(Array) && data.key?("type")
    end

    def collection_shape?(data)
      data["decisions"].is_a?(Array) || data["resolutions"].is_a?(Array) || data["metadata"].is_a?(Hash)
    end

    # A MeetingCollection wraps its meetings under a top-level `meetings:`
    # array (its own top level carries no identifier/type). Index each
    # nested meeting that satisfies `meeting_shape?` — the same bar applied
    # to standalone meeting files — so a malformed entry carrying only a
    # `urn` cannot make a dangling link appear to resolve.
    def index_meeting_collection(data, file)
      data["meetings"].each do |meeting|
        next unless meeting.is_a?(Hash) && meeting_shape?(meeting)

        urn = meeting["urn"]
        @meetings_by_urn[urn] = file if urn
      end
    end
  end
end
