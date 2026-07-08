# frozen_string_literal: true

module Edoxen
  # Generic document reference (used by AgendaItem.references). `kind`
  # is a free-form discriminator (e.g., "standard", "document",
  # "ballot", "resolution"); the schema leaves it open deliberately so
  # new reference kinds need no schema change.
  class Reference < Lutaml::Model::Serializable
    attribute :ref, :string
    attribute :kind, :string
    attribute :title, LocalizedString, collection: true
  end
end
