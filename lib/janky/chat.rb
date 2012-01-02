module Janky
  module Chat
    # Setup the Chat.
    #
    # settings - environment variables
    #
    # Returns nothing.
    def self.setup(name, settings)
      desired = name.to_sym
      if candidate_service = @registered_services.detect{ |k,v| k == desired}
        @service = candidate_service.last
        @service.setup(settings)
        @default_room_name = settings["JANKY_CHAT_DEFAULT_ROOM"]
      else
        raise ArgumentError, "Invalid chat service '#{desired}' requested. Valid values are: #{@registered_services.keys.join(', ')}"
      end
    end

    class << self
      attr_accessor :service
      attr_accessor :default_room_name
      attr_accessor :registered_services
    end

    def self.default_room_id
      room_id(default_room_name)
    end

    # Send a message to a Chat room.
    #
    # message - The String message.
    # room_id - The Integer room ID.
    # opts    - Option hash to pass the chat service client
    #
    # Returns nothing.
    def self.speak(message, room_id, opts=nil)
      service.speak(message, room_id, opts)
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
    # Returns an Array of Janky::Chat::Room objects.
    def self.rooms
      service.rooms
    end

    # Enable mocking. Once enabled, messages are discarded.
    #
    # Returns nothing.
    def self.enable_mock!
      @service = Mock.new
    end

    # Configure available rooms. Only available in mock mode.
    #
    # value - Hash of room map (Fixnum ID => String name)
    #
    # Returns nothing.
    def self.rooms=(value)
      service.rooms = value
    end
  end
end
