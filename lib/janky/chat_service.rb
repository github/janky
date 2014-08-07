module Janky
  module ChatService
    Room = Struct.new(:id, :name)

    # Setup the adapter used to notify chat rooms of build status.
    #
    # name     - Service name as a string.
    # settings - Service-specific setting hash.
    # default  - Name of the default chat room as a String.
    #
    # Returns nothing.
    def self.setup(name, settings, default)
      klass = adapters[name]

      if !klass
        raise Error, "Unknown chat service: #{name.inspect}. Available " \
          "services are #{adapters.keys.join(", ")}"
      end

      @adapter = klass.new(settings)
      @default_room_name = default
    end

    class << self
      attr_accessor :adapter, :default_room_name
    end

    # Registry of available chat implementations.
    def self.adapters
      @adapters ||= {}
    end

    def self.default_room_id
      room_id(default_room_name)
    end

    # Send a message to a Chat room.
    #
    # message - The String message.
    # room_id - The String room ID.
    # options - Optional hash passed to the chat adapter.
    #
    # Returns nothing.
    def self.speak(message, room_id, options = {})
      adapter.speak(message, room_id, options)
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
    # id - the String room ID.
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
    # Returns an Array of Room objects.
    def self.rooms
      adapter.rooms
    end

    # Enable mocking. Once enabled, messages are discarded.
    #
    # Returns nothing.
    def self.enable_mock!
      @adapter = Mock.new
    end

    # Configure available rooms. Only available in mock mode.
    #
    # value - Hash of room map (String ID => String name)
    #
    # Returns nothing.
    def self.rooms=(value)
      adapter.rooms = value
    end
  end
end
