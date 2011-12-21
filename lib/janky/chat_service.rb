module Janky
  module ChatService
    # Setup the Chat.
    #
    # adapter - Chat adapter implementation to notify with.
    #
    # Returns nothing.
    def self.setup(adapter)
      @adapter = adapter
    end

    def self.method_missing(meth, *args, &block)
      @adapter.send(meth, *args)
    end

  end
end
