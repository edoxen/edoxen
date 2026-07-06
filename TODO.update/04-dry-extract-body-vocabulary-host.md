# 04 — DRY: extract `BodyVocabularyHost` module

## Symptom

`DecisionMetadata` (`lib/edoxen/decision_metadata.rb:21,34-40`) and
`MeetingCollectionMetadata`
(`lib/edoxen/meeting_collection_metadata.rb:13,18-24`) both:

1. Declare `attribute :body_vocabulary, BodyVocabularyEntry, collection: true`.
2. Define `def canonical_type_for(body_type)` with the same 5-line body.

Two classes, two copies of the same behaviour. DRY violation.

## Fix

Introduce a Ruby module that encapsulates both the attribute and the
lookup, then `include` it on both metadata classes:

```ruby
# lib/edoxen/body_vocabulary_host.rb
module Edoxen
  module BodyVocabularyHost
    def self.included(base)
      base.attribute :body_vocabulary, BodyVocabularyEntry, collection: true
    end

    def canonical_type_for(body_type)
      return body_type if body_type.nil? || body_type.to_s.empty?
      return body_type unless body_vocabulary

      entry = body_vocabulary.find { |e| e.body_type == body_type }
      entry ? entry.canonical_type : body_type
    end
  end
end
```

Then on both classes:

```ruby
class DecisionMetadata < Lutaml::Model::Serializable
  include BodyVocabularyHost
  # ... drop the local attribute + method
end
```

Register autoload in `lib/edoxen.rb`.

## Notes

- The lutaml-model `attribute` declaration needs to run when the class
  is being defined. `included(base)` hook with `base.attribute(...)` is
  the standard idiom.
- The module is **only** mixed into metadata classes; do not include it
  on entities that have `body_type` but not `body_vocabulary[]`
  (Decision, Meeting, MeetingComponent). Those entities *use* the
  vocabulary via their parent collection's lookup, not directly.

## Acceptance

1. `body_vocabulary_spec.rb` still passes.
2. No remaining `def canonical_type_for` in `lib/edoxen/`.
3. The schema_model_sync_spec still passes (attribute is still declared
   via the module hook).
