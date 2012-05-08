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

    def self.default_room
      default_room_name
    end

    # Send a message to a Chat room.
    #
    # message - The String message.
    # room - The room.
    # options - Optional hash passed to the chat adapter.
    #
    # Returns nothing.
    def self.speak(message, room, options = {})
      adapter.speak(message, room, options)
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
  end
end
