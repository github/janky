module Janky
  module Notifier
    class FailureService < ChatService
      def self.completed(build)
        return if build.green?
        return unless failure_room = ENV["JANKY_CHAT_FAILURE_ROOM"]
        ::Janky::ChatService.speak(message(build), failure_room, {:color => color(build)})
      end
    end
  end
end
