module Janky
  module ChatService
    # Sends messages to HipChat and accesses available rooms.
    module HipChat
      # Setup the HipChat client with the given credentials.
      #
      # token   - the HipChat API token as a String.
      # default - the name of the default HipChat room as a String.
      #
      # Returns nothing.
      def self.setup(token, default)
        self.token = token
        self.default_room_name = default
      end

      class << self
        attr_accessor :token
        attr_accessor :default_room_name
      end

      def self.default_room_id
        room_id(default_room_name)
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

      # Enable mocking. Once enabled, messages are discarded.
      #
      # Returns nothing.
      def self.enable_mock!
        @adapter = Mock.new
      end

      # Configure available rooms. Only available in mock mode.
      #
      # value - Hash of room map (Fixnum ID => String name)
      #
      # Returns nothing.
      def self.rooms=(value)
        adapter.rooms = value
      end

      def self.adapter
        @adapter ||= ::HipChat::Client.new(token)
      end

      class Mock
        def initialize
          @rooms = {}
        end

        attr_writer :rooms

        def speak(room_name, message)
          if !@rooms.values.include?(room_name)
            raise Error, "Unknown room #{room_name.inspect}"
          end
        end

        def rooms
          require 'ostruct'
          acc = []
          @rooms.each do |id, name|
            acc << OpenStruct.new("room_id" => id, "name" => name)
          end
          acc
        end
      end
    end
  end
end
