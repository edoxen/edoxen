# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe Edoxen::LinkChecker do
  def write(dir, name, content)
    File.write(File.join(dir, name), content)
  end

  # A DecisionCollection whose metadata links to `meeting_urn`.
  def write_decisions(dir, meeting_urn)
    write(dir, "decisions.yaml", <<~YAML)
      ---
      metadata:
        meeting_urn: #{meeting_urn}
      decisions: []
    YAML
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
      write_decisions(dir, "urn:oiml:ciml:meeting:ciml-1")
      expect(described_class.check(dir)).to be_empty
    end
  end

  it "reports a dangling meeting_urn on a DecisionCollection" do
    Dir.mktmpdir do |dir|
      write_decisions(dir, "urn:oiml:ciml:meeting:ciml-99")
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

  it "ignores YAML with unsupported aliases silently" do
    Dir.mktmpdir do |dir|
      write(dir, "aliased.yaml", "a: &x 1\nb: *x\n")
      expect { described_class.check(dir) }.not_to raise_error
    end
  end

  it "resolves links across documents that carry native date scalars" do
    Dir.mktmpdir do |dir|
      write(dir, "meeting.yaml", <<~YAML)
        ---
        identifier:
        - prefix: CIML
          number: '56'
        urn: urn:oiml:ciml:meeting:ciml-56
        type: plenary
        scheduled_date_range:
          start: 2025-10-13
          end: 2025-10-15
      YAML
      write(dir, "decisions.yaml", <<~YAML)
        ---
        metadata:
          meeting_urn: urn:oiml:ciml:meeting:ciml-56
          date: 2025-10-13
        decisions: []
      YAML
      expect(described_class.check(dir)).to be_empty
    end
  end

  it "resolves a meeting_urn that points at a meeting nested in a MeetingCollection" do
    Dir.mktmpdir do |dir|
      write(dir, "meetings.yaml", <<~YAML)
        ---
        metadata:
          title: CIML meetings
        meetings:
        - identifier:
          - prefix: CIML
            number: '55'
          urn: urn:oiml:ciml:meeting:ciml-55
          type: plenary
        - identifier:
          - prefix: CIML
            number: '56'
          urn: urn:oiml:ciml:meeting:ciml-56
          type: plenary
      YAML
      write_decisions(dir, "urn:oiml:ciml:meeting:ciml-56")
      expect(described_class.check(dir)).to be_empty
    end
  end

  it "still reports a dangling meeting_urn absent from a MeetingCollection" do
    Dir.mktmpdir do |dir|
      write(dir, "meetings.yaml", <<~YAML)
        ---
        metadata:
          title: CIML meetings
        meetings:
        - identifier:
          - prefix: CIML
            number: '55'
          urn: urn:oiml:ciml:meeting:ciml-55
          type: plenary
      YAML
      write_decisions(dir, "urn:oiml:ciml:meeting:ciml-99")
      errs = described_class.check(dir)
      expect(errs.size).to eq(1)
      expect(errs.first.urn).to eq("urn:oiml:ciml:meeting:ciml-99")
      expect(errs.first.kind).to eq("no matching Meeting")
    end
  end

  it "does not resolve a meeting_urn against a malformed meetings entry lacking meeting shape" do
    Dir.mktmpdir do |dir|
      write(dir, "meetings.yaml", <<~YAML)
        ---
        metadata:
          title: CIML meetings
        meetings:
        - urn: urn:oiml:ciml:meeting:ciml-77
      YAML
      write_decisions(dir, "urn:oiml:ciml:meeting:ciml-77")
      errs = described_class.check(dir)
      expect(errs.size).to eq(1)
      expect(errs.first.urn).to eq("urn:oiml:ciml:meeting:ciml-77")
      expect(errs.first.kind).to eq("no matching Meeting")
    end
  end

  it "resolves links across documents that carry native Time scalars" do
    Dir.mktmpdir do |dir|
      write(dir, "meeting.yaml", <<~YAML)
        ---
        identifier:
        - prefix: CIML
          number: '57'
        urn: urn:oiml:ciml:meeting:ciml-57
        type: plenary
        scheduled_date_range:
          start: 2025-10-13
      YAML
      write(dir, "decisions.yaml", <<~YAML)
        ---
        metadata:
          meeting_urn: urn:oiml:ciml:meeting:ciml-57
          called_at: 2025-10-13T09:00:00+02:00
        decisions: []
      YAML
      expect(described_class.check(dir)).to be_empty
    end
  end

  it "indexes an empty MeetingCollection without error" do
    Dir.mktmpdir do |dir|
      write(dir, "meetings.yaml", <<~YAML)
        ---
        metadata:
          title: Empty
        meetings: []
      YAML
      expect(described_class.check(dir)).to be_empty
    end
  end

  it "reports a duplicate Meeting URN across two standalone files" do
    Dir.mktmpdir do |dir|
      meeting_yaml = <<~YAML
        ---
        identifier:
        - prefix: CIML
          number: '55'
        urn: urn:oiml:ciml:meeting:ciml-55
        type: plenary
      YAML
      write(dir, "meeting-a.yaml", meeting_yaml)
      write(dir, "meeting-b.yaml", meeting_yaml)
      errs = described_class.check(dir)
      expect(errs.size).to eq(1)
      expect(errs.first.urn).to eq("urn:oiml:ciml:meeting:ciml-55")
      expect(errs.first.kind).to start_with("duplicate Meeting URN")
      expect(errs.first.kind).to include("meeting-a.yaml")
    end
  end

  it "reports a duplicate Meeting URN within a MeetingCollection" do
    Dir.mktmpdir do |dir|
      write(dir, "meetings.yaml", <<~YAML)
        ---
        metadata:
          title: CIML meetings
        meetings:
        - identifier:
          - prefix: CIML
            number: '55'
          urn: urn:oiml:ciml:meeting:ciml-55
          type: plenary
        - identifier:
          - prefix: CIML
            number: '55'
          urn: urn:oiml:ciml:meeting:ciml-55
          type: plenary
      YAML
      errs = described_class.check(dir)
      expect(errs.size).to eq(1)
      expect(errs.first.urn).to eq("urn:oiml:ciml:meeting:ciml-55")
      expect(errs.first.kind).to start_with("duplicate Meeting URN")
      expect(errs.first.pointer).to eq("meetings[1].urn")
    end
  end

  it "includes a 1-based line number in dangling-URN errors" do
    Dir.mktmpdir do |dir|
      write(dir, "decisions.yaml", <<~YAML)
        ---
        metadata:
          title: placeholder
          meeting_urn: urn:oiml:ciml:meeting:ciml-99
        decisions: []
      YAML
      errs = described_class.check(dir)
      expect(errs.size).to eq(1)
      expect(errs.first.line).to be >= 1
      expect(errs.first.message).to match(/decisions\.yaml:\d+: /)
      expect(errs.first.message).to include("metadata.meeting_urn")
    end
  end

  it "scans .yml files in addition to .yaml" do
    Dir.mktmpdir do |dir|
      write(dir, "meeting.yml", <<~YAML)
        ---
        identifier:
        - prefix: CIML
          number: '1'
        urn: urn:oiml:ciml:meeting:ciml-1
        type: plenary
      YAML
      write_decisions(dir, "urn:oiml:ciml:meeting:ciml-1")
      expect(described_class.check(dir)).to be_empty
    end
  end

  it "walks nested directories recursively" do
    Dir.mktmpdir do |dir|
      nested = File.join(dir, "a", "b")
      FileUtils.mkdir_p(nested)
      File.write(File.join(nested, "meeting.yaml"), <<~YAML)
        ---
        identifier:
        - prefix: CIML
          number: '1'
        urn: urn:oiml:ciml:meeting:ciml-1
        type: plenary
      YAML
      write_decisions(dir, "urn:oiml:ciml:meeting:ciml-1")
      expect(described_class.check(dir)).to be_empty
    end
  end

  it "does not classify a MeetingSeries as a Meeting" do
    # MeetingSeries has identifier + kind, not identifier + type —
    # it must NOT be indexed as a Meeting.
    Dir.mktmpdir do |dir|
      write(dir, "series.yaml", <<~YAML)
        ---
        identifier:
        - prefix: CIML
          number: '1'
        urn: urn:oiml:ciml:series:1
        kind: plenary
        name: CIML Plenary Series
      YAML
      write_decisions(dir, "urn:oiml:ciml:series:1")
      errs = described_class.check(dir)
      expect(errs.size).to eq(1)
      expect(errs.first.kind).to eq("no matching Meeting")
    end
  end

  it "does not classify a metadata-only YAML as a DecisionCollection" do
    # regression for the dropped `metadata.is_a?(Hash)` branch —
    # a random `_data/foo.yaml` with only metadata must not be
    # treated as a DecisionCollection.
    Dir.mktmpdir do |dir|
      write(dir, "committee.yaml", <<~YAML)
        ---
        metadata:
          title: Just committee metadata
      YAML
      expect(described_class.check(dir)).to be_empty
    end
  end

  it "keeps the first claim when two files assert the same URN (no dangling false-positive)" do
    Dir.mktmpdir do |dir|
      meeting_yaml = <<~YAML
        ---
        identifier:
        - prefix: CIML
          number: '55'
        urn: urn:oiml:ciml:meeting:ciml-55
        type: plenary
      YAML
      write(dir, "meeting-a.yaml", meeting_yaml)
      write(dir, "meeting-b.yaml", meeting_yaml)
      write_decisions(dir, "urn:oiml:ciml:meeting:ciml-55")
      errs = described_class.check(dir)
      # The duplicate-URN error is reported, but the dangling-link
      # check still resolves the meeting_urn against the first claim.
      expect(errs.any? { |e| e.kind == "no matching Meeting" }).to be false
    end
  end
end
