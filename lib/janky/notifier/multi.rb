module Janky
  module Notifier
    # Dispatches notifications to multiple notifiers.
    class Multi
      def initialize(notifiers)
        @notifiers = notifiers
      end

      def queued(build)
        @notifiers.each do |notifier|
          notifier.queued(build) if notifier.respond_to?(:queued)
        end
      end

      def started(build)
        @notifiers.each do |notifier|
          notifier.started(build) if notifier.respond_to?(:started)
        end
      end

      def completed(build)
        @notifiers.each do |notifier|
          notifier.completed(build) if notifier.respond_to?(:completed)
        end
      end
    end
  end
end
