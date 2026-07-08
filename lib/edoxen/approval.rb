# frozen_string_literal: true

module Edoxen
  # Approval record: type (affirmative / negative), degree (consensus level),
  # date of the approval event, and a human-readable elaboration.
  class Approval < Lutaml::Model::Serializable
    attribute :type, :string, values: Enums::APPROVAL_TYPE
    attribute :degree, :string, values: Enums::APPROVAL_DEGREE
    attribute :date, DecisionDate
    attribute :message, LocalizedString, collection: true
  end
end
