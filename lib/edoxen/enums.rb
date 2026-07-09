# frozen_string_literal: true

module Edoxen
  # Single source of truth for every enum used by the Edoxen information model.
  #
  # Mirrors ../edoxen-model/models/*.lutaml, deduped.
  # Both:
  #   * Ruby model attribute declarations (`attribute :type, :string, values: Enums::ACTION_TYPE`)
  #   * JSON-Schema (`schema/edoxen.yaml`)
  # reference these constants.
  #
  # The schema <-> Ruby enum-sync spec asserts the YAML schema's enum arrays
  # equal these arrays. If you change a constant here, change the schema in
  # the same PR.
  module Enums
    ACTION_TYPE = %w[
      adopts thanks approves decides declares asks invites
      resolves confirms welcomes recommends requests congratulates
      instructs urges appoints calls-upon encourages affirms elects
      authorizes charges states remarks judges sanctions abrogates empowers
    ].freeze

    CONSIDERATION_TYPE = %w[
      having noting recognizing acknowledging recalling reaffirming
      considering taking-into-account pursuant-to bearing-in-mind
      emphasizing concerned accepts observing referring acting empowers
    ].freeze

    # --- Decision-side (was Resolution; renamed 2026-07) -----------------

    # DecisionKind — what kind of formal outcome this is. `resolution` is
    # one value; the same formal concept has many names across bodies
    # (order, ruling, determination, finding, opinion, etc.).
    DECISION_KIND = %w[
      resolution order ruling determination
      recommendation statement finding opinion other
    ].freeze

    # DecisionKindCanonical — short abstract classification of decision
    # kinds. Cap: 5 canonical values (hard limit per the design review).
    DECISION_KIND_CANONICAL = %w[decision recommendation statement finding other].freeze

    # DecisionStatus — lifecycle state machine.
    DECISION_STATUS = %w[
      draft proposed under_consideration
      decided negatived withdrawn deferred
    ].freeze

    DECISION_RELATION_TYPE = %w[
      annex_of has_annex updates refines replaces considers cites
    ].freeze

    DECISION_DATE_TYPE = %w[
      adoption drafted discussed proposed decided negatived withdrawn published effective
    ].freeze

    APPROVAL_TYPE = %w[affirmative negative].freeze

    APPROVAL_DEGREE = %w[unanimous majority minority].freeze

    URL_KIND = %w[access report].freeze

    # --- Meeting/Agenda side ----------------------------------------------
    # Mirrors edoxen-model/models/{meeting,agenda,...}_*.lutaml.
    # schema/meeting.yaml references these via $defs/<EnumName>.enum.

    MEETING_TYPE = %w[
      plenary working_group task_group ad_hoc joint general_assembly
      committee subcommittee conference workshop seminar webinar hearing
      markup board_meeting annual_general_meeting other
    ].freeze

    # MeetingTypeCanonical — short abstract classification of meeting
    # types. Cap: 4 canonical values (no `other`).
    MEETING_TYPE_CANONICAL = %w[plenary governing working advisory].freeze

    MEETING_STATUS = %w[upcoming completed cancelled].freeze

    AGENDA_STATUS = %w[draft final amended cancelled superseded].freeze

    AGENDA_ITEM_KIND = %w[numbered unnumbered header opening closing aob].freeze

    AGENDA_ITEM_OUTCOME = %w[discussed resolved deferred adopted withdrawn carried negatived].freeze

    HOST_TYPE = %w[national_body liaison associate organizer].freeze

    MEETING_RELATION_TYPE = %w[
      continues_from continues_to joint_with supersedes superseded_by rescheduled_from rescheduled_to
      parent_of child_of sibling_of depends_on
      finish_to_start finish_to_finish start_to_start start_to_finish
    ].freeze

    SOURCE_URL_KIND = %w[
      agenda_pdf minutes_pdf decisions_pdf report_pdf register_url landing_page
    ].freeze

    PARTICIPATION_STATUS = %w[present absent apologies observer excused].freeze

    VOTE_TYPE = %w[
      affirmative negative abstain absent not_applicable
    ].freeze

    # --- New in 1.0 (broadened scope) -----------------------------------

    VENUE_KIND = %w[physical virtual].freeze

    VIRTUAL_FEATURE = %w[audio video chat phone screen feed].freeze

    VISIBILITY = %w[public private confidential].freeze

    ATTENDANCE_ROLE = %w[chair required optional non_participant].freeze

    # iCalendar PARTSTAT, plain English (no jargon).
    ATTENDANCE_RESPONSE = %w[
      pending confirmed declined tentative delegated
    ].freeze

    COMPONENT_KIND = %w[
      track session debate breakout bof
      plenary_session working_group_session committee_of_the_whole
      keynote address statement question_time
      opening closing break reception registration networking other
    ].freeze

    # ComponentKindCanonical — the short abstract set (1.0, 1.0 design review).
    # `other` is a temporary escape while the vocabulary stabilises.
    #
    # Cap: 5 canonical values.
    COMPONENT_KIND_CANONICAL = %w[deliberative working ceremonial break other].freeze

    MOTION_STATUS = %w[
      introduced seconded debating question_put voting
      carried negatived withdrawn lapsed
    ].freeze

    # Terminal MotionStatus values — `Motion#pending?` is the complement.
    # Kept as a separate constant (not derived) because the partition is
    # semantic, not lexical; the spec in motion_spec.rb asserts the union
    # equals MOTION_STATUS and the intersection is empty (MECE).
    MOTION_TERMINAL = %w[carried negatived withdrawn lapsed].freeze

    VOTING_STATUS = %w[called in_progress decided withdrawn deferred].freeze

    VOTING_METHOD = %w[
      voice division show_of_hands roll_call electronic
      secret_ballot unanimous_consent consensus
    ].freeze

    VOTING_OUTCOME = %w[passed negatived tied withdrawn].freeze

    TOPIC_STATUS = %w[open under_discussion decided deferred withdrawn].freeze

    OFFICER_ROLE = %w[
      chair vice_chair deputy_chair secretary treasurer
      parliamentarian presiding_officer sergeant_at_arms other
    ].freeze

    RECURRENCE_FREQ = %w[
      secondly minutely hourly daily weekly monthly yearly
    ].freeze

    # Polymorphic communication channel. OCP: adding a new kind does
    # not change the model — only this enum (or use `other` + extensions).
    CONTACT_METHOD_KIND = %w[
      phone mobile fax email url mail pager message other
    ].freeze

    # Polymorphic external identifier for a Contact (ORCID, ISNI,
    # Wikidata, ROR, etc.). OCP: adding a new scheme only extends this
    # enum (or use `other` + extensions).
    CONTACT_IDENTIFIER_KIND = %w[
      orcid isni wikidata ror ringgold github other
    ].freeze
  end
end
