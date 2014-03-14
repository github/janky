module Janky
  module Notifier
    # Mock notifier implementation used in testing environments.
    class Mock
      def initialize
        @notifications = []
      end

      attr_reader :notifications

      def queued(build)
      end

      def reset!
        @notifications.clear
      end

      def started(build)
      end

      def completed(build)
        notify(:completed, build)
      end

      def notify(state, build)
        @notifications << [state, build]
      end

      def success?(repo, branch, room_name)
        room_name ||= Janky::ChatService.default_room_name

        builds = @notifications.select do |state, build|
          state == :completed &&
            build.green? &&
            build.repo_name   == repo &&
            build.branch_name == branch &&
            build.room_name   == room_name
        end

        builds.size == 1
      end

      def failure?(repo, branch, room_name)
        room_name ||= Janky::ChatService.default_room_name

        builds = @notifications.select do |state, build|
          state == :completed &&
            build.red? &&
            build.repo_name   == repo &&
            build.branch_name == branch &&
            build.room_name   == room_name
        end

        builds.size == 1
      end
    end
  end
end
