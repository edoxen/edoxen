# frozen_string_literal: true

module Edoxen
  # MeetingExtension — the profile mechanism (ISO 8601-2 §15).
  # Every core entity has an `extensions: MeetingExtension[0..*]` slot.
  # Adopters register their own profile namespace (e.g. "legco",
  # "us-congress", "ietf") and define `kind` values within it.
  #
  # Field semantics (tightened 1.0, per 1.0 design review):
  #
  #   profile    — the profile namespace (lowercase, hyphen-separated).
  #   kind       — discriminator within the profile.
  #   ref        — URN of the profile document this extension references.
  #   attributes — typed key/value pairs (ExtensionAttribute).
  #
  # Recursion (`extensions: MeetingExtension[0..*]`) was removed in
  # 1.0 — no documented use case. Profiles needing nesting can encode
  # it via dotted keys ("vote.count", "vote.method") in `attributes[]`.
  class MeetingExtension < Lutaml::Model::Serializable
    attribute :profile, :string
    attribute :kind, :string
    attribute :ref, :string
    attribute :attributes, ExtensionAttribute, collection: true
  end
end
