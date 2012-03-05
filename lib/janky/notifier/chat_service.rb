module Janky
  module Notifier
    class ChatService
      def self.completed(build)
        unless build.green?
          message = "Build #%s (%s) of %s/%s failed (%ss) %s" % [
            build.number,
            build.sha1,
            build.repo_name,
            build.branch_name,
            build.duration,
            build.compare
          ]
  
          ::Janky::ChatService.speak(message, build.room_id, {:color => "red"})
        end
      end
    end
  end
end
