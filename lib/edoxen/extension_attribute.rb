# frozen_string_literal: true

module Edoxen
  # ExtensionAttribute — one typed key/value pair within a
  # MeetingExtension. Polymorphic on value type so consumers don't
  # have to re-parse strings back into Int/Float/Bool/Date.
  #
  # Wire form (1.0+, per 1.0 design review):
  #
  #   - key: "quorum"
  #     type: "integer"
  #     intValue: 7
  #
  #   - key: "name"
  #     type: "string"
  #     value: "quic"      # string variant uses bare `value` (1.0 wire)
  #
  #   - key: "start"
  #     type: "datetime"
  #     dateTimeValue: 2026-07-04T10:00:00Z
  #
  # The `type` discriminator tells consumers which value field to read
  # without probing all six. Exactly one of the value fields should be
  # set; the schema enforces this.
  #
  # String values use the bare `value:` wire name for back-compat with
  # 1.0 fixtures. Typed variants (integer/float/boolean/date/datetime)
  # use camelCase wire names. The gem unifies them behind `#typed_value`.
  class ExtensionAttribute < Lutaml::Model::Serializable
    attribute :key, :string

    # String variant — Ruby attribute is `value`, wire name is `value`
    # (matches 1.0; `type: "string"` discriminator added in 1.0).
    attribute :value, :string

    # Typed variants — added in 1.0.
    attribute :integer_value, :integer
    attribute :float_value, :float
    attribute :boolean_value, :boolean
    attribute :date_value, :date
    attribute :date_time_value, :date_time

    # Wire discriminator: "string" | "integer" | "float" | "boolean" |
    # "date" | "datetime". Tells consumers which value field to read.
    attribute :type, :string

    key_value do
      map "key", to: :key
      map "type", to: :type
      map "value", to: :value
      map "intValue", to: :integer_value
      map "floatValue", to: :float_value
      map "booleanValue", to: :boolean_value
      map "dateValue", to: :date_value
      map "dateTimeValue", to: :date_time_value
    end

    # Convenience: read whichever typed value is set. Returns nil when
    # none of the value fields is populated.
    def typed_value
      case type
      when "integer"  then integer_value
      when "float"    then float_value
      when "boolean"  then boolean_value unless boolean_value.nil?
      when "date"     then date_value
      when "datetime" then date_time_value
      else
        # Default to string for back-compat with 1.0 (no `type`).
        value
      end
    end

    # Back-compat alias — 1.0 introduced `value` as the canonical Ruby
    # attribute; the older `string_value` alias keeps callers that
    # already migrated to that name working.
    alias string_value value
  end
end
