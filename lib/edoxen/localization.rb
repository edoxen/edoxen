# frozen_string_literal: true

module Edoxen
  # A monolingual rendering of a Decision. Mirrors the glossarist
  # LocalizedConcept pattern: language-agnostic fields live on the
  # parent Decision; per-language content lives here.
  class Localization < Lutaml::Model::Serializable
    attribute :language_code, :string
    attribute :script, :string
    attribute :title, :string
    attribute :subject, :string
    attribute :message, :string
    attribute :considering, :string
    attribute :considerations, Consideration, collection: true
    attribute :approvals, Approval, collection: true
    attribute :actions, Action, collection: true
  end
end
