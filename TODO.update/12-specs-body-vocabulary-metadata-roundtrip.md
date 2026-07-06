# 12 — Specs: body_vocabulary metadata-level YAML round-trip

## Symptom

`body_vocabulary_spec.rb` covers `BodyVocabularyEntry` standalone and
the `canonical_type_for` lookup via Ruby constructors, but no spec
parses a metadata block like:

```yaml
metadata:
  body_vocabulary:
    - body_type: "Resolution"
      canonical_type: "decision"
    - body_type: "Order"
      canonical_type: "decision"
```

through `DecisionMetadata.from_yaml(...)` and asserts the lookup works
end-to-end. Same gap on `MeetingCollectionMetadata`. If the
`body_vocabulary` collection ever stops parsing (e.g. lutaml-model
regression on nested typed collections), only the YAML-round-trip spec
would catch it — and that spec doesn't exist.

## Fix

Add two examples (one per metadata class) that:

1. Construct a YAML payload with a non-trivial `body_vocabulary[]`.
2. Parse via `from_yaml`.
3. Assert `metadata.body_vocabulary.size` and
   `metadata.canonical_type_for("CIML Meeting")` return the expected
   values.
4. Round-trip through `to_yaml` and re-parse to confirm shape
   preservation.

## Acceptance

1. Two new examples in `body_vocabulary_spec.rb` (or a new
   `body_vocabulary_metadata_spec.rb`).
2. Both green.
3. `bundle exec rspec` count +2.
