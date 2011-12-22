module Janky
  module ChatService
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
      def self.speak(message, room_id, color=nil)
        adapter.speak(room_name(room_id), message)
      end

      # Get the ID of a room.
      #
      # slug - the String name of the room.
      #
      # Returns the room ID or nil for unknown rooms.
      def self.room_id(name)
        if room = rooms.detect { |room| room.name == name }
          room.id
        end
      end

      # Get the name of a room given its ID.
      #
      # id - the Fixnum room ID.
      #
      # Returns the name as a String or nil when not found.
      def self.room_name(id)
        if room = rooms.detect { |room| room.id.to_s == id.to_s }
          room.name
        end
      end

      # Get a list of all rooms names.
      #
      # Returns an Array of room name as Strings.
      def self.room_names
        rooms.map { |room| room.name }.sort
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
