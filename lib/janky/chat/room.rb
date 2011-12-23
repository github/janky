module Janky
  module Chat
    class Room

      def initialize(id, name)
        @id = id
        @name = name
      end

      attr_accessor :id
      attr_accessor :name

    end
  end
end
