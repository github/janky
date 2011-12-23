module Janky
  module Chat
    # Sends messages to Campfire and accesses available rooms.
    module Campfire
      # Setup the Campfire client with the given credentials.
      #
      # settings - environment variables
      #
      # Returns nothing.
      def self.setup(settings)
        ::Broach.settings = {
          "account" => settings['JANKY_CAMPFIRE_ACCOUNT'],
          "token"   => settings['JANKY_CAMPFIRE_TOKEN'],
          "use_ssl" => true
        }
      end

      # Send a message to a Campfire room.
      #
      # message - The String message.
      # room_id - The Integer room ID.
      #
      # Returns nothing.
      def self.speak(message, room_id, opts={})
        ::Broach.speak(Chat.room_name(room_id), message)
      end

      # Memoized list of available rooms.
      #
      # Returns an Array of Broach::Room objects.
      def self.rooms
        @rooms ||= ::Broach.rooms.map{|r| Room.new(r.id, r.name) }
      end
    end
  end
end
