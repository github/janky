module Janky
  module Notifier
    # Setup the notifier.
    #
    # notifiers - One or more notifiers implementation to notify with.
    #
    # Returns nothing.
    def self.setup(notifiers)
      @adapter = Multi.new(Array(notifiers))
    end

    # Called whenever a build is queued
    #
    # build - the Build record.
    #
    # Returns nothing
    def self.queued(build)
      adapter.queued(build)
    end

    # Called whenever a build starts.
    #
    # build - the Build record.
    #
    # Returns nothing.
    def self.started(build)
      adapter.started(build)
    end

    # Called whenever a build completes.
    #
    # build - the Build record.
    #
    # Returns nothing.
    def self.completed(build)
      adapter.completed(build)
    end

    # The implementation used to send notifications.
    #
    # Returns a Multi instance by default or Mock when in mock mode.
    def self.adapter
      @adapter ||= Multi.new(@notifiers)
    end

    # Enable mocking. Once enabled, notifications are stored in a
    # in-memory Array exposed by the notifications method.
    #
    # Returns nothing.
    def self.enable_mock!
      @adapter = Mock.new
    end

    # Reset notification log. Only available when mocked. Typically called
    # before each test.
    #
    # Returns nothing.
    def self.reset!
      adapter.reset!
    end

    # Was any notification sent out? Only available when mocked.
    #
    # Returns a Boolean.
    def self.empty?
      notifications.empty?
    end

    # Was a success notification sent to the given room for the given
    # repo and branch?
    #
    # repo   - the String repository name.
    # branch - the String branch name.
    # room   - the optional String Campfire room slug.
    #
    # Returns a boolean.
    def self.success?(repo, branch, room=nil)
      adapter.success?(repo, branch, room)
    end

    # Same as `success?` but for failed notifications.
    def self.failure?(repo, branch, room=nil)
      adapter.failure?(repo, branch, room)
    end

    # Access the notification log. Only available when mocked.
    #
    # Returns an Array of notified Builds.
    def self.notifications
      adapter.notifications
    end
  end
end
