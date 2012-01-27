module Janky
  module Notifier
    class Chat
      def self.completed(build)
        status = build.green? ? "was successful" : "failed"
        color = build.green? ? "green" : "red"

        message = "Build #%s (%s) of %s/%s %s (%ss) <a href='%s'>%s</a>" % [
          build.number,
          build.sha1,
          build.repo_name,
          build.branch_name,
          status,
          build.duration,
	  build.compare,
          build.compare
        ]

        ::Janky::Chat.speak(message, build.room_id, {:color => color})
      end
    end
  end
end
