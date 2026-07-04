# frozen_string_literal: true

require "edoxen"

require_relative "support/extension_host_shared_examples"
require_relative "support/lutaml_parser"

RSpec.configure do |config|
  # Persist pass/fail status so subsequent runs can target only the failing
  # examples (`bundle exec rspec --only-failures`).
  config.example_status_persistence_file_path = ".rspec_status"

  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
