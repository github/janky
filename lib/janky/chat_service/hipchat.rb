require "hipchat"

module Janky
  module ChatService
    class HipChat
      def initialize(settings)
        @client = ::HipChat::Client.new(settings["JANKY_CHAT_HIPCHAT_TOKEN"])
        @from = settings["JANKY_CHAT_HIPCHAT_FROM"] || "CI"
      end

      def speak(message, room_id, options = {:color => "yellow"})
        @client[room_id].send(@from, message, options)
      end

      def rooms
        @rooms ||= @client.rooms.map do |room|
          Room.new(room.room_id, room.name)
        end
      end
    end
  end

  register_chat_service "hipchat", ChatService::HipChat
end
