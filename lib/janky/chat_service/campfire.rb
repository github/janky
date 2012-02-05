module Janky
  module ChatService
    class Campfire
      def initialize(settings)
        Broach.settings = {
          "account" => settings['JANKY_CHAT_CAMPFIRE_ACCOUNT'],
          "token"   => settings['JANKY_CHAT_CAMPFIRE_TOKEN'],
          "use_ssl" => true
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
