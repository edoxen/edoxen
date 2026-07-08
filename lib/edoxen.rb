# frozen_string_literal: true

require "lutaml/model"

# Configure the lutaml-model serialization framework used throughout the
# Edoxen information-model gem.
Lutaml::Model::Config.configure do |c|
  c.yaml_adapter_type = :standard_yaml
  c.json_adapter_type = :standard_json
end

module Edoxen
  # Autoload every constant defined under the Edoxen namespace from its
  # native `lib/edoxen/<name>.rb` file. This is the only place where file
  # paths are tied to constants; everywhere else, models reference each
  # other by class name (resolved lazily by Ruby).
  #
  # There are intentionally NO `require_relative` calls in this gem —
  # autoload keeps load-order semantics clean and lets us tolerate the
  # extensive cross-references between model classes
  # (Decision <-> Localization, DecisionMetadata <-> Localization, etc.).
  autoload :VERSION, "edoxen/version"
  autoload :Error, "edoxen/error"
  autoload :ValidationError, "edoxen/error"
  autoload :Enums, "edoxen/enums"
  autoload :ReferenceData, "edoxen/reference_data"

  # --- Shared behaviours (mixed into entity + metadata classes) --------
  autoload :OfficersHost, "edoxen/officers_host"
  autoload :BodyVocabularyHost, "edoxen/body_vocabulary_host"

  # --- Decision side ----------------------------------------------------
  autoload :StructuredIdentifier, "edoxen/structured_identifier"
  autoload :MeetingIdentifier, "edoxen/meeting_identifier"
  autoload :DecisionDate, "edoxen/decision_date"
  autoload :Action, "edoxen/action"
  autoload :Approval, "edoxen/approval"
  autoload :Consideration, "edoxen/consideration"
  autoload :SourceUrl, "edoxen/source_url"
  autoload :Url, "edoxen/url"
  autoload :DecisionRelation, "edoxen/decision_relation"
  autoload :Decision, "edoxen/decision"
  autoload :DecisionMetadata, "edoxen/decision_metadata"
  autoload :DecisionCollection, "edoxen/decision_collection"

  # --- Meeting/Agenda side ----------------------------------------------
  autoload :DateRange, "edoxen/date_range"
  autoload :ContactMethod, "edoxen/contact_method"
  autoload :ContactIdentifier, "edoxen/contact_identifier"
  autoload :Name, "edoxen/name"
  autoload :Contact, "edoxen/contact"
  autoload :LocalizedString, "edoxen/localized_string"
  autoload :LocalizedName, "edoxen/localized_name"
  autoload :Person, "edoxen/person"
  autoload :HostRef, "edoxen/host_ref"
  autoload :Deadline, "edoxen/deadline"
  autoload :Reference, "edoxen/reference"
  autoload :AgendaItem, "edoxen/agenda_item"
  autoload :Agenda, "edoxen/agenda"
  autoload :Attendance, "edoxen/attendance"
  autoload :VoteRecord, "edoxen/vote_record"
  autoload :MinutesSection, "edoxen/minutes_section"
  autoload :Minutes, "edoxen/minutes"
  autoload :MeetingRelation, "edoxen/meeting_relation"
  autoload :Meeting, "edoxen/meeting"
  autoload :MeetingCollectionMetadata, "edoxen/meeting_collection_metadata"
  autoload :MeetingCollection, "edoxen/meeting_collection"

  # --- v2 broadened-scope entities --------------------------------------
  autoload :ExtensionAttribute, "edoxen/extension_attribute"
  autoload :MeetingExtension, "edoxen/meeting_extension"
  autoload :BodyVocabularyEntry, "edoxen/body_vocabulary_entry"
  autoload :EntityRef, "edoxen/entity_ref"
  autoload :Venue, "edoxen/venue"
  autoload :PhysicalVenue, "edoxen/physical_venue"
  autoload :VirtualVenue, "edoxen/virtual_venue"
  autoload :Motion, "edoxen/motion"
  autoload :VotingCounts, "edoxen/voting_counts"
  autoload :Voting, "edoxen/voting"
  autoload :TopicDocument, "edoxen/topic_document"
  autoload :TopicAsset, "edoxen/topic_asset"
  autoload :Topic, "edoxen/topic"
  autoload :RecurrenceByDay, "edoxen/recurrence_by_day"
  autoload :Recurrence, "edoxen/recurrence"
  autoload :MeetingSeries, "edoxen/meeting_series"
  autoload :MeetingComponent, "edoxen/meeting_component"
  autoload :Officer, "edoxen/officer"
  autoload :VenueValidator, "edoxen/venue_validator"
  autoload :ContactCollection, "edoxen/contact_collection"
  autoload :VenueCollection, "edoxen/venue_collection"
  autoload :Urn, "edoxen/urn"

  # --- Services ---------------------------------------------------------
  autoload :SchemaValidator, "edoxen/schema_validator"
  autoload :LinkChecker, "edoxen/link_checker"
  autoload :Cli, "edoxen/cli"
end
