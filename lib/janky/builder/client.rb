module Janky
  module Builder
    class Client
      def initialize(url, callback_url)
        @url          = URI(url)
        @callback_url = URI(callback_url)
      end

      # The String absolute URL of the Jenkins server.
      attr_reader :url

      # The String absoulte URL callback of this Janky host.
      attr_reader :callback_url

      # Trigger a Jenkins build for the given Build.
      #
      # build - a Build object.
      #
      # Returns the Jenkins build URL.
      def run(build)
        Runner.new(@url, build, adapter).run
      end

      # Stop the Jenkins build for the given Build.
      #
      # build - a Build object.
      #
      # Returns nothing.
      def stop(build)
        Runner.new(@url, build, adapter).stop
      end

      # Retrieve the output of the given Build.
      #
      # build - a Build object. Must have an url attribute.
      #
      # Returns the String build output.
      def output(build)
        Runner.new(@url, build, adapter).output
      end

      # Setup a job on the Jenkins server.
      #
      # name          - The desired job name as a String.
      # repo_uri      - The repository git URI as a String.
      # template_path - The Pathname to the XML config template.
      #
      # Returns nothing.
      def setup(name, repo_uri, template_path)
        job_creator.run(name, repo_uri, template_path)
      end

      # The adapter used to trigger builds. Defaults to HTTP, which hits the
      # Jenkins server configured by `setup`.
      def adapter
        @adapter ||= HTTP.new(url.user, url.password)
      end

      def job_creator
        @job_creator ||= JobCreator.new(url, @callback_url)
      end

      # Enable the mock adapter and make subsequent builds green.
      def green!
        @adapter = Mock.new(true, Janky.app)
        job_creator.enable_mock!
      end

      # Alias green! as enable_mock!
      alias_method :enable_mock!, :green!

      # Alias green! as reset!
      alias_method :reset!, :green!

      # Enable the mock adapter and make subsequent builds red.
      def red!
        @adapter = Mock.new(false, Janky.app)
      end

      # Simulate the first callback. Only available when mocked.
      def start!
        @adapter.start
      end

      # Simulate the last callback. Only available when mocked.
      def complete!
        @adapter.complete
      end
    end
  end
end
