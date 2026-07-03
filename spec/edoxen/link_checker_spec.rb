# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

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
        date_range:
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
end
