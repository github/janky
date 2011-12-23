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
        @client = ::HipChat::Client.new(settings['JANKY_HIPCHAT_TOKEN'])
        @from = settings['JANKY_HIPCHAT_FROM'] || 'CI'
      end

      class << self
        attr_accessor :client
        attr_accessor :from # Name the message will appear be sent from
      end

      # Send a message to a HipChat room.
      #
      # message - The String message.
      # room_id - The Integer room ID.
      #
      # Returns nothing.
      def self.speak(message, room_id, output={:color => 'yellow'})
        client[room_id].send(from, message, output[:color])
      end

      # Memoized list of available rooms.
      #
      # Returns an Array of HipChat::Room objects.
      def self.rooms
        @rooms ||= client.rooms.map{|r| Room.new(r.room_id, r.name) }
      end
    end
  end
end
