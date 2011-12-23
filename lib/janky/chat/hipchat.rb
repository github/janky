module Janky
  module Chat
    module HipChat

      def self.setup(settings)
        @client = ::HipChat::Client.new(settings['JANKY_HIPCHAT_TOKEN'])
        @from = settings['JANKY_HIPCHAT_FROM'] || 'CI'
      end

      class << self
        attr_accessor :client
        attr_accessor :from # Name the message will appear be sent from
      end

      def self.speak(message, room_id, opts={:color => 'yellow'})
        client[room_id].send(from, message, opts[:color])
      end

      def self.rooms
        @rooms ||= client.rooms.map{|r| Room.new(r.room_id, r.name) }
      end
    end
  end
end
