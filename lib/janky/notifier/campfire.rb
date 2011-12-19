module Janky
  module Notifier
    class Campfire
      def self.completed(build)
        status  = build.green? ? "was successful" : "failed"

        message = "Build #%s (%s) of %s/%s %s (%ss) %s" % [
          build.number,
          build.sha1,
          build.repo_name,
          build.branch_name,
          status,
          build.duration,
          build.compare
        ]

        ::Janky::Campfire.speak(message, build.room_id)
      end
    end
  end
end
