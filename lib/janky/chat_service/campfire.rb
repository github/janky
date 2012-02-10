module Janky
  module ChatService
    class Campfire
      def initialize(settings)
        account = settings["JANKY_CHAT_CAMPFIRE_ACCOUNT"]
        if account.nil? || account.empty?
          raise Error, "JANKY_CHAT_CAMPFIRE_ACCOUNT setting is required"
        end

        token = settings["JANKY_CHAT_CAMPFIRE_TOKEN"]
        if token.nil? || token.empty?
          raise Error, "JANKY_CHAT_CAMPFIRE_TOKEN setting is required"
        end

        Broach.settings = {
          "account" => account,
          "token"   => token,
          "use_ssl" => true,
        }
      end

      def speak(message, room_id, opts={})
        Broach.speak(ChatService.room_name(room_id), message)
      end

      def rooms
        @rooms ||= Broach.rooms.map do |room|
          Room.new(room.id, room.name)
        end
      end
    end
  end
end
