# frozen_string_literal: true

module Edoxen
  # One remark made by one or more meeting members on a topic or
  # a minutes section. The `kind` discriminator separates the
  # three BS 0:2006 statement types (statement, comment,
  # standpoint); adding a new kind is a one-line StatementKind
  # enum extension (OCP).
  #
  # Attachment points: `MinutesSection#statements[]` (per-meeting)
  # and `Topic#statements[]` (standing position that travels with
  # the topic across meetings). Same class, two attachment points
  # — the semantic distinction comes from where the statement is
  # attached, not from a subclass.
  class Statement < Lutaml::Model::Serializable
    attribute :kind, :string, values: Enums::STATEMENT_KIND
    attribute :description, LocalizedString, collection: true
    attribute :party, Person, collection: true
    attribute :extensions, MeetingExtension, collection: true
  end
end
