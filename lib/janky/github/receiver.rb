module Janky
  module GitHub
    # Rack app handling GitHub Post-Receive [1] requests.
    #
    # The JSON payload is parsed into a GitHub::Payload. We then find the
    # associated Repository record based on the Payload's repository git URL
    # and create the associated records: Branch, Commit and Build.
    #
    # Finally, we trigger a new Jenkins build.
    #
    # [1]: http://help.github.com/post-receive-hooks/
    class Receiver
      def initialize(secret)
        @secret = secret
      end

      def call(env)
        dup.call!(env)
      end

      def call!(env)
        @request = Rack::Request.new(env)

        if pull_request?
          post_last_build if pull_request_opened?
          return Rack::Response.new("OK", 200).finish
        end

        if !valid_signature?
          return Rack::Response.new("Invalid signature", 403).finish
        end

        if !payload.head_commit
          return Rack::Response.new("Ignored", 400).finish
        end

        result = BuildRequest.handle(
          payload.uri,
          payload.branch,
          payload.pusher,
          payload.head_commit,
          payload.compare,
          @request.POST["room"]
        )

        Rack::Response.new("OK: #{result}", 201).finish
      end

      def valid_signature?
        digest    = OpenSSL::Digest::Digest.new("sha1")
        signature = @request.env["HTTP_X_HUB_SIGNATURE"].split("=").last

        signature == OpenSSL::HMAC.hexdigest(digest, @secret, data)
      end

      def pull_request?
        @request.env["HTTP_X_GITHUB_EVENT"] == "pull_request"
      end

      def pull_request_opened?
        pull_request["action"] == "opened" 
      end

      def pull_request
        @pull_request ||= Yajl.load(data)
      end

      def last_build
        commit = ::Janky::Commit.find_by_sha1(pull_request["pull_request"]["head"]["sha"])
        return unless commit
        commit.last_build
      end

      def post_last_build
        ::Janky::Notifier::GithubPullRequestService.new(ENV).completed(last_build) if last_build
      end

      def payload
        @payload ||= GitHub::Payload.parse(data)
      end

      def data
        @data ||= data!
      end

      def data!
        if @request.content_type != "application/json"
          return Rack::Response.new("Invalid Content-Type", 400).finish
        end

        body = ""
        @request.body.each { |chunk| body << chunk }
        body
      end
    end
  end
end
