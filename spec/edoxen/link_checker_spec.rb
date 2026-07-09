# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Edoxen::LinkChecker do
  def write(dir, name, content)
    File.write(File.join(dir, name), content)
  end

  it "returns no errors when every URN resolves" do
    Dir.mktmpdir do |dir|
      write(dir, "meeting-1.yaml", <<~YAML)
        ---
        identifier:
        - prefix: CIML
          number: '1'
        urn: urn:oiml:ciml:meeting:ciml-1
        type: plenary
      YAML
      write(dir, "decisions.yaml", <<~YAML)
        ---
        metadata:
          meeting_urn: urn:oiml:ciml:meeting:ciml-1
        decisions: []
      YAML
      expect(described_class.check(dir)).to be_empty
    end
  end

  it "reports a dangling meeting_urn on a DecisionCollection" do
    Dir.mktmpdir do |dir|
      write(dir, "decisions.yaml", <<~YAML)
        ---
        metadata:
          meeting_urn: urn:oiml:ciml:meeting:ciml-99
        decisions: []
      YAML
      errs = described_class.check(dir)
      expect(errs.size).to eq(1)
      expect(errs.first.urn).to eq("urn:oiml:ciml:meeting:ciml-99")
      expect(errs.first.kind).to eq("no matching Meeting")
    end
  end

  it "is tolerant of files that are neither Meetings nor DecisionCollections" do
    Dir.mktmpdir do |dir|
      write(dir, "noise.yaml", <<~YAML)
        ---
        title: Just metadata
        description: Not a meeting or decision collection
      YAML
      expect(described_class.check(dir)).to be_empty
    end
  end

  it "ignores malformed YAML silently (returns empty for the file)" do
    Dir.mktmpdir do |dir|
      write(dir, "broken.yaml", "title: [unterminated")
      expect { described_class.check(dir) }.not_to raise_error
    end
  end

  describe "MeetingCollection shape" do
    it "indexes every Meeting urn inside the collection" do
      Dir.mktmpdir do |dir|
        write(dir, "meetings.yaml", <<~YAML)
          ---
          metadata:
            title: All meetings
          meetings:
            - identifier:
                - prefix: CIML
                  number: '1'
              urn: urn:oiml:ciml:meeting:ciml-1
              type: plenary
            - identifier:
                - prefix: CIML
                  number: '2'
              urn: urn:oiml:ciml:meeting:ciml-2
              type: plenary
        YAML
        write(dir, "decisions.yaml", <<~YAML)
          ---
          metadata:
            meeting_urn: urn:oiml:ciml:meeting:ciml-2
          decisions: []
        YAML
        expect(described_class.check(dir)).to be_empty
      end
    end
  end

  describe "MeetingSeries shape" do
    it "indexes the series urn so collections can reference it" do
      Dir.mktmpdir do |dir|
        write(dir, "series.yaml", <<~YAML)
          ---
          identifier:
          - prefix: CIML
            number: series
          urn: urn:oiml:ciml:meeting-series:main
          meeting_refs:
          - urn:oiml:ciml:meeting:ciml-1
        YAML
        # Even though a collection typically targets a Meeting urn
        # (not a series), the series itself must be classified as a
        # meeting-shape document rather than skipped or misrouted.
        results = described_class.check(dir)
        expect(results).to be_empty
      end
    end

    it "recognises a series via identifier + recurrence (no meeting_refs)" do
      Dir.mktmpdir do |dir|
        write(dir, "series.yaml", <<~YAML)
          ---
          identifier:
          - prefix: CIML
            number: series
          urn: urn:oiml:ciml:meeting-series:main
          recurrence:
            freq: yearly
        YAML
        expect(described_class.check(dir)).to be_empty
      end
    end
  end

  describe "regression: pre-1.0 shapes are not classified" do
    it "does not treat a `resolutions:` key as a DecisionCollection" do
      Dir.mktmpdir do |dir|
        write(dir, "legacy.yaml", <<~YAML)
          ---
          metadata:
            meeting_urn: urn:oiml:ciml:meeting:ciml-99
          resolutions: []
        YAML
        # Pre-1.0 `resolutions` is no longer sniffed as a collection
        # shape — the file is treated as unknown and produces no error.
        expect(described_class.check(dir)).to be_empty
      end
    end

    it "does not treat every metadata block as a DecisionCollection" do
      Dir.mktmpdir do |dir|
        write(dir, "meeting.yaml", <<~YAML)
          ---
          identifier:
          - prefix: CIML
            number: '1'
          urn: urn:oiml:ciml:meeting:ciml-1
          type: plenary
          metadata:
            title: Side note on the wire
        YAML
        # A Meeting with a metadata-shaped block must NOT be
        # misclassified as a DecisionCollection.
        expect(described_class.check(dir)).to be_empty
      end
    end
  end
end
