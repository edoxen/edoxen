# frozen_string_literal: true

module Edoxen
  # VirtualVenue — a virtual place where a Meeting happens.
  # Carries a URI (tel:, https:, sip:, xmpp:, rtsp:), the iCalendar
  # FEATURE set (audio/video/chat/phone/screen/feed), and access
  # details (passcode, meeting_id, dial-in numbers, waiting room,
  # registration requirement).
  class VirtualVenue < Venue
    attribute :uri, :string
    attribute :features, :string, collection: true, values: Enums::VIRTUAL_FEATURE
    attribute :passcode, :string
    attribute :meeting_id, :string
    attribute :dial_in_numbers, :string, collection: true
    attribute :waiting_room, :boolean
    attribute :registration_required, :boolean

    def features_list
      features&.join(", ") || ""
    end
  end
end
