# frozen_string_literal: true

module Edoxen
  # URN helpers for entities that don't carry their URN inline (e.g.
  # AgendaItem which derives its URN from the parent Meeting). The
  # scheme is hierarchical:
  #
  #   urn:oiml:{body}:{kind}:{slug}(:{sub-kind}:{sub-id})*
  #
  # Examples:
  #   urn:oiml:ciml:meeting:ciml-60
  #   urn:oiml:ciml:meeting:ciml-60:agenda:6.2
  #   urn:oiml:doc:ciml:resolution:2025-01
  #
  # Use {UrnFor.agenda_item} to compute an agenda item URN from its
  # parent meeting URN + label, and {UrnFor.parse} to decompose one.
  module UrnFor
    AGENDA_SEGMENT = "agenda"
    SEGMENT_RE = /[^:]+/

    # Build an AgendaItem URN from its parent Meeting URN and the
    # agenda item label (e.g. "6.2"). Returns nil if either input is
    # blank so callers can use this as a default-value generator
    # without raising.
    def self.agenda_item(meeting_urn:, label:)
      m = meeting_urn.to_s
      l = label.to_s
      return nil if m.empty? || l.empty?

      "#{m}:#{AGENDA_SEGMENT}:#{l}"
    end

    # Parse an agenda item URN into its component parts. Returns a Hash
    # with :meeting_urn and :label keys, or nil if the URN doesn't
    # match the expected shape.
    #
    #   UrnFor.parse("urn:oiml:ciml:meeting:ciml-60:agenda:6.2")
    #   # => { meeting_urn: "urn:oiml:ciml:meeting:ciml-60",
    #   #      label: "6.2" }
    def self.parse(urn)
      return nil unless urn

      s = urn.to_s
      idx = s.rindex(":#{AGENDA_SEGMENT}:")
      return nil unless idx

      meeting_urn = s[0...idx]
      label = s[(idx + AGENDA_SEGMENT.length + 2)..]
      return nil if meeting_urn.empty? || label.to_s.empty?

      { meeting_urn: meeting_urn, label: label }
    end

    # Walk an Agenda tree and set each item's `urn` based on the
    # parent meeting URN. Skips items that already have a URN. Useful
    # as a backfill step in data-fix scripts.
    def self.assign_to_agenda!(agenda, meeting_urn)
      return nil unless agenda && meeting_urn

      (agenda.items || []).each do |item|
        next if item.urn && !item.urn.to_s.empty?

        item.urn = agenda_item(meeting_urn: meeting_urn, label: item.label)
      end
      agenda
    end
  end
end
