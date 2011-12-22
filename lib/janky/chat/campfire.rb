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
        @adapter = Broach.new
      end

      class << self
        attr_accessor :adapter
      end

      # Send a message to a Campfire room.
      #
      # message - The String message.
      # room_id - The Integer room ID.
      #
      # Returns nothing.
      def self.speak(message, room_id, output={})
        adapter.speak(room_name(room_id), message)
      end

      # Memoized list of available rooms.
      #
      # Returns an Array of Broach::Room objects.
      def self.rooms
        @rooms ||= adapter.rooms
      end

      class Broach
        def speak(room_name, message)
          ::Broach.speak(room_name, message)
        end

        def rooms
          ::Broach.rooms
        end
      end


    end
  end
end
