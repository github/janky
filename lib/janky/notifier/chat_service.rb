module Janky
  module Notifier
    class ChatService
      def self.completed(build)
        status = build.green? ? "was successful" : "failed"
        color = build.green? ? "green" : "red"

        message = "Build #%s (%s) of %s/%s %s (%ss) %s" % [
          build.number,
          build.sha1[0..7],
          build.repo_name,
          build.branch_name,
          status,
          build.duration,
          build.compare
        ]

        ::Janky::ChatService.speak(message, build.room_id, {:color => color})
      end
    end
  end
end
