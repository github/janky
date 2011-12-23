module Janky
  module Chat
    module Campfire

      def self.setup(settings)
        ::Broach.settings = {
          "account" => settings['JANKY_CAMPFIRE_ACCOUNT'],
          "token"   => settings['JANKY_CAMPFIRE_TOKEN'],
          "use_ssl" => true
        }
      end

      def self.speak(message, room_id, opts={})
        ::Broach.speak(Chat.room_name(room_id), message)
      end

      def self.rooms
        @rooms ||= ::Broach.rooms.map{|r| Room.new(r.id, r.name) }
      end
    end
  end
end
