# frozen_string_literal: true

require "yaml"
require "date"

module Edoxen
  # Walks a directory tree of Meeting and DecisionCollection YAML
  # files and asserts that every cross-document URN link resolves.
  #
  # Invariants enforced:
  #
  #   * Every Meeting#urn (if set) is unique across the scanned tree.
  #   * Every DecisionCollection#metadata.meeting_urn (if set)
  #     resolves to a Meeting whose urn matches.
  #
  # Use from CLI / scripts via the public `check` class method. Returns
  # an array of `LinkError` records (empty = ok).
  #
  # All file IO is read-only. No edits to the YAMLs.
  #
  # Architecture: two passes.
  #
  #   1. `index_pass` walks every file, classifies its top-level shape
  #      via one of three MECE predicates (`meeting_collection_shape?`,
  #      `meeting_shape?`, `decision_collection_shape?`), and records
  #      URN → IndexEntry pairs. Duplicate URNs are reported here.
  #   2. `verify_pass` checks every cross-document link in the indexed
  #      collections against the indexed meetings.
  #
  # Adding a new link type is one new field-reading line in
  # `index_pass` (if the source side needs indexing) plus one
  # iteration in `verify_pass`. Adding a new top-level shape is one
  # new predicate + one new branch in `index_pass`.
  class LinkChecker
    # Internal: file + line pair carried by the URN indexes.
    IndexEntry = Struct.new(:file, :line)

    # Cross-document link failure. `line` is 1-based. `pointer` is the
    # dotted in-document path that carries the bad reference (e.g.
    # `metadata.meeting_urn` or `meetings[2].urn`).
    LinkError = Struct.new(:file, :line, :pointer, :urn, :kind) do
      def message
        "#{file}:#{line}: #{pointer} references #{urn} (#{kind})"
      end

      alias_method :to_clickable_format, :message
    end

    # Walk `dir` (recursive scan of *.yaml and *.yml), classify each
    # file, and assert every cross-document URN resolves to a real
    # record.
    #
    # @return [Array<LinkError>] empty when all links resolve.
    def self.check(dir)
      new(dir).check
    end

    def initialize(dir)
      @dir = dir
      @meetings_by_urn = {} # urn → IndexEntry(file, line)
      @collections_by_meeting_urn = {} # meeting_urn → IndexEntry(file, line)
    end

    def check
      errors = []
      index_pass(errors)
      verify_pass(errors)
      errors
    end

    private

    # Phase 1: walk the tree, classify each file, populate the URN
    # indexes. Reports duplicate-URN errors as they surface — the
    # first claim keeps the index slot; subsequent claimants are
    # rejected and flagged, so dangling-link reports always point at
    # the authoritative source.
    def index_pass(errors)
      # `Dir.glob` order is filesystem-dependent; the duplicate-URN
      # specs assert on which file is the "first claim", so sort
      # explicitly for determinism.
      Dir.glob(File.join(@dir, "**", "*.{yaml,yml}")).sort.each do |file| # rubocop:disable Lint/RedundantDirGlobSort
        content = File.read(file)
        data = safe_load_yaml(content)
        next unless data.is_a?(Hash)

        line_map = SchemaValidator::LineMap.build(content)

        case data
        when ->(d) { meeting_collection_shape?(d) }
          index_meeting_collection(data, file, line_map, errors)
        when ->(d) { meeting_shape?(d) }
          line = line_of(line_map, "/urn")
          register_meeting(data["urn"], file, line, "urn", errors) if data["urn"]
        when ->(d) { decision_collection_shape?(d) }
          index_decision_collection(data, file, line_map)
        end
      end
    end

    # Phase 2: every cross-document link is checked here. New link
    # types land as additional iterations over the relevant index.
    def verify_pass(errors)
      @collections_by_meeting_urn.each do |meeting_urn, entry|
        next if @meetings_by_urn.key?(meeting_urn)

        errors << LinkError.new(entry.file, entry.line, "metadata.meeting_urn", meeting_urn,
                                "no matching Meeting")
      end
    end

    # ---- Shape predicates (MECE) --------------------------------------
    #
    # The three predicates partition the universe of edoxen YAML
    # shapes that participate in cross-document URN linking. Files
    # that match none of them (e.g. MeetingSeries, random `_data/*.yaml`)
    # are silently skipped.

    # A MeetingCollection wraps its meetings under a top-level
    # `meetings:` array. Its own top level carries no `identifier` or
    # `type`, so this predicate is disjoint from `meeting_shape?`.
    def meeting_collection_shape?(data)
      data["meetings"].is_a?(Array)
    end

    # A standalone Meeting carries `identifier` (array) and `type`.
    # MeetingSeries has `identifier` + `kind` (no `type`), so it is
    # correctly excluded — MeetingSeries does not yet participate in
    # cross-document URN linking.
    def meeting_shape?(data)
      data["identifier"].is_a?(Array) && data.key?("type")
    end

    # A DecisionCollection carries `decisions` or `resolutions`. The
    # earlier `metadata.is_a?(Hash)` branch was too permissive — it
    # matched any file with a top-level `metadata:` key, including
    # unrelated YAML. A real DecisionCollection always has one of the
    # two collection keys.
    def decision_collection_shape?(data)
      data["decisions"].is_a?(Array) || data["resolutions"].is_a?(Array)
    end

    # ---- Indexers -----------------------------------------------------

    # Index each nested meeting that satisfies `meeting_shape?` — the
    # same bar applied to standalone meeting files — so a malformed
    # entry carrying only a `urn` cannot make a dangling link appear
    # to resolve. Duplicate URNs are reported via `register_meeting`.
    def index_meeting_collection(data, file, line_map, errors)
      data["meetings"].each_with_index do |meeting, idx|
        next unless meeting.is_a?(Hash) && meeting_shape?(meeting)
        next unless meeting["urn"]

        line = line_of(line_map, "/meetings/#{idx}/urn")
        register_meeting(meeting["urn"], file, line, "meetings[#{idx}].urn", errors)
      end
    end

    def index_decision_collection(data, file, line_map)
      meeting_urn = data.dig("metadata", "meeting_urn")
      return unless meeting_urn

      line = line_of(line_map, "/metadata/meeting_urn")
      @collections_by_meeting_urn[meeting_urn] = IndexEntry.new(file, line)
    end

    # Record a Meeting#urn → file/line entry. A second claim on the
    # same URN is reported as a duplicate-URN error and the index
    # keeps the first claim (so dangling-link reports point at the
    # authoritative source, not the most-recent overwrite).
    def register_meeting(urn, file, line, pointer, errors)
      prior = @meetings_by_urn[urn]
      if prior
        errors << LinkError.new(file, line, pointer, urn,
                                "duplicate Meeting URN (first seen at #{prior.file}:#{prior.line})")
        return
      end

      @meetings_by_urn[urn] = IndexEntry.new(file, line)
    end

    # ---- Helpers ------------------------------------------------------

    def line_of(line_map, json_pointer)
      SchemaValidator::LineMap.locate(json_pointer, line_map).first
    end

    def safe_load_yaml(content)
      YAML.safe_load(content, permitted_classes: [Date, Time])
    rescue Psych::Exception, ArgumentError
      nil
    end
  end
end
