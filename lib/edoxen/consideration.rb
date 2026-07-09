# frozen_string_literal: true

module Edoxen
  # Basis for a Decision: a verb (having, noting, considering, ...) plus
  # one effective date and the per-field Localized reasoning. Each
  # `Consideration` belongs to a `Decision`; the message field carries
  # one `LocalizedString` per ISO 24229 spelling.
  class Consideration < Lutaml::Model::Serializable
    attribute :type, :string, values: Enums::CONSIDERATION_TYPE
    attribute :date_effective, DecisionDate
    attribute :message, LocalizedString, collection: true
  end
end
