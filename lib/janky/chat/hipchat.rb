module Janky
  module Chat
    # Sends messages to HipChat and accesses available rooms.
    module HipChat
      # Setup the HipChat client with the given credentials.
      #
      # settings - environment variables
      #
      # Returns nothing.
      def self.setup(settings)
        @adapter = ::HipChat::Client.new(settings['JANKY_HIPCHAT_TOKEN'])
      end

      class << self
        attr_accessor :adapter
      end

      # Send a message to a HipChat room.
      #
      # message - The String message.
      # room_id - The Integer room ID.
      #
      # Returns nothing.
      def self.speak(message, room_id, color='yellow')
        adapter[room_id].send('Janky', message, :color => color)
      end

      # Get the ID of a room.
      #
      # slug - the String name of the room.
      #
      # Returns the room ID or nil for unknown rooms.
      def self.room_id(name)
        if room = rooms.detect { |room| room.name == name }
          room.room_id
        end
      end

      # Get the name of a room given its ID.
      #
      # id - the Fixnum room ID.
      #
      # Returns the name as a String or nil when not found.
      def self.room_name(id)
        if room = rooms.detect { |room| room.room_id.to_s == id.to_s }
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
      # Returns an Array of HipChat::Room objects.
      def self.rooms
        @rooms ||= adapter.rooms
      end
    end
  end
end
