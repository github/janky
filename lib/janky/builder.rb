module Janky
  # Triggers Jenkins builds and handles callbacks.
  #
  # The HTTP requests flow goes like this:
  #
  # 1. Send a Build request to the Jenkins server over HTTP. The resulting
  #    build URL is stored in Build#url.
  #
  # 2. Once Jenkins picks up the build and starts running it, it sends a callback
  #    handled by the `receiver` Rack app, which transitions the build into a
  #    building state.
  #
  # 3. Finally, Jenkins sends another callback with the build result and the
  #    build is transitioned to a completed and green/red state.
  #
  # The Mock adapter provides methods to simulate that flow without having to
  # go over the wire.
  module Builder
    # Set the callback URL of builder clients. Must be called before
    # registering any client.
    #
    # callback_url - The absolute callback URL as a String.
    #
    # Returns nothing.
    def self.setup(callback_url)
      @callback_url = callback_url
    end

    # Public: Define the rule for picking a builder.
    #
    # block - Required block that will be given a Repository object when
    #         picking a builder. Must return a Client object.
    #
    # Returns nothing.
    def self.choose(&block)
      @chooser = block
    end

    # Pick the appropriate builder for a repo based on the rule set by the
    # choose method. Uses the default builder when no rule is defined.
    #
    # repo - a Repository object.
    #
    # Returns a Client object.
    def self.pick_for(repo)
      if block = @chooser
        block.call(repo)
      else
        self[:default]
      end
    end

    # Register a new build host.
    #
    # url - The String URL of the Jenkins server.
    #
    # Returns the new Client instance.
    def self.[]=(builder, url)
      builders[builder] = Client.new(url, @callback_url)
    end

    # Get the Client for a registered build host.
    #
    # builder - the String name of the build host.
    #
    # Returns the Client instance.
    def self.[](builder)
      builders[builder] ||
        raise(Error, "Unknown builder: #{builder.inspect}")
    end

    # Registered build hosts.
    #
    # Returns an Array of Client.
    def self.builders
      @builders ||= {}
    end

    # Rack app handling HTTP callbacks coming from the Jenkins server.
    def self.receiver
      @receiver ||= Janky::Builder::Receiver
    end

    def self.enable_mock!
      builders.values.each { |b| b.enable_mock! }
    end

    def self.green!
      builders.values.each { |b| b.green! }
    end

    def self.red!
      builders.values.each { |b| b.red! }
    end

    def self.reset!
      builders.values.each { |b| b.reset! }
    end

    def self.start!
      builders.values.each { |b| b.start! }
    end

    def self.complete!
      builders.values.each { |b| b.complete! }
    end
  end
end
