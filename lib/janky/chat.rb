module Janky
  module Chat
    # Setup the Chat.
    #
    # settings - environment variables
    #
    # Returns nothing.
    def self.setup(settings)
      s = Janky::Chat.constants.detect do |chat|
        chat.to_s.casecmp(settings["JANKY_CHAT_SERVICE"] || 'Campfire') == 0
      end
      @service = Janky::Chat.const_get(s)
      service.setup(settings)
      # fall back to the legacy naming for default room
      @default_room_name = settings["JANKY_CHAT_DEFAULT_ROOM"] || settings["JANKY_CAMPFIRE_DEFAULT_ROOM"]
    end

    class << self
      attr_accessor :service
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
    def self.speak(message, room_id, output=nil)
      service.speak(message, room_id, output)
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
          acc << OpenStruct.new("id" => id, "name" => name, "room_id" => id)
        end
        acc
      end
    end

  end
end
