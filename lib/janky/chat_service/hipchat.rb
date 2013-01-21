require "hipchat"

module Janky
  module ChatService
    class HipChat
      def initialize(settings)
        token = settings["JANKY_CHAT_HIPCHAT_TOKEN"]
        if token.nil? || token.empty?
          raise Error, "JANKY_CHAT_HIPCHAT_TOKEN setting is required"
        end

        @client = ::HipChat::Client.new(token)
        @from = settings["JANKY_CHAT_HIPCHAT_FROM"] || "CI"
      end

      def speak(message, room_id, options = {})
        default = {
          :color => "yellow",
          :message_format => "text"
        }
        options = default.merge(options)
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
