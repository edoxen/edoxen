# frozen_string_literal: true

module Edoxen
  # A Contact that is specifically an individual human. Inherits all
  # Contact fields. The old `email`, `phone`, and `orcid` fields are
  # replaced by entries in `contact_methods` (kind=email / kind=phone)
  # and `identifiers` (kind=orcid).
  class Person < Contact
  end
end
