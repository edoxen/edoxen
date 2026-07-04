# frozen_string_literal: true

require_relative "lib/edoxen/version"

Gem::Specification.new do |spec|
  spec.name = "edoxen"
  spec.version = Edoxen::VERSION
  spec.authors = ["Ribose Inc."]
  spec.email = ["open.source@ribose.com"]

  spec.summary = "Edoxen is a generic information model for meetings, agendas, and decisions."
  spec.description = <<~HEREDOC
    Edoxen provides a Ruby library for working with a generic meeting/decision
    model, allowing users to create, manipulate, and serialize meeting, agenda,
    motion, voting, and decision data in a structured format. Built on top of
    the lutaml-model serialization framework, with profile-based customization
    (ISO 8601-2 §15) for domain-specific extensions.
  HEREDOC

  spec.homepage = "https://github.com/metanorma/edoxen"
  spec.license = "BSD-2-Clause"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/metanorma/edoxen"
  spec.metadata["changelog_uri"] = "https://github.com/metanorma/edoxen"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "json_schemer", "~> 2.0"
  spec.add_dependency "lutaml-model", "~> 0.7"
  spec.add_dependency "thor", "~> 1.0"
  spec.add_dependency "unlocodes", "~> 0.3"
  spec.add_dependency "iata", "~> 0.1"
end
