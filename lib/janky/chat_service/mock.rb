module Janky
  module ChatService
    # Mock chat implementation used in testing environments.
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
          acc << Room.new(id, name)
        end
        acc
      end
    end
  end
end
