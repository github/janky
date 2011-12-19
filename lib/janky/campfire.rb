module Janky
  # Sends messages to Campfire and accesses available rooms.
  module Campfire
    # Setup the Campfire client with the given credentials.
    #
    # account - the Campfire account name as a String.
    # token   - the Campfire API token as a String.
    # default - the name of the default Campfire room as a String.
    #
    # Returns nothing.
    def self.setup(account, token, default)
      ::Broach.settings = {
        "account" => account,
        "token"   => token,
        "use_ssl" => true
      }

      self.default_room_name = default
    end

    class << self
      attr_accessor :default_room_name
    end

    def self.default_room_id
      room_id(default_room_name)
    end

    # Send a message to a Campfire room.
    #
    # message - The String message.
    # room_id - The Integer room ID.
    #
    # Returns nothing.
    def self.speak(message, room_id)
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
      @adapter ||= Broach.new
    end

    class Broach
      def speak(room_name, message)
        ::Broach.speak(room_name, message)
      end

      def rooms
        ::Broach.rooms
      end
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
        acc = []
        @rooms.each do |id, name|
          acc << ::Broach::Room.new("id" => id, "name" => name)
        end
        acc
      end
    end
  end
end
