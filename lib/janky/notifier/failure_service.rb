module Janky
  module Notifier
    class FailureService < ChatService
      def self.completed(build)
        return unless need_failure_notification?(build)
        ::Janky::ChatService.speak(message(build), failure_room, {:color => color(build)})
      end

      def self.failure_room
        ENV["JANKY_CHAT_FAILURE_ROOM"]
      end

      def self.need_failure_notification?(build)
        build.red? && failure_room != build.room_id
      end
    end
  end
end
