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
end
