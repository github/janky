module Janky
  module Notifier
    class Chat
      def self.completed(build)
        status, color  = build.green? ? ["was successful","green"] : ["failed","red"]

        message = "Build #%s (%s) of %s/%s %s (%ss) %s" % [
          build.number,
          build.sha1,
          build.repo_name,
          build.branch_name,
          status,
          build.duration,
          build.compare
        ]

        ::Janky::Chat.speak(message, build.room_id, color)
      end
    end
  end
end
