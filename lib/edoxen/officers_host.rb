# frozen_string_literal: true

module Edoxen
  # Mixed into entities that carry an `officers` collection. Provides
  # `officers_with_role(role)` and the `chair` accessor so Meeting and
  # MeetingComponent share a single implementation.
  #
  # The including class must declare an `officers` attribute whose
  # entries expose `role` and `person`.
  module OfficersHost
    def officers_with_role(role)
      (officers || []).select { |o| o.role == role.to_s }
    end

    def chair
      officers_with_role("chair").first&.person
    end
  end
end
