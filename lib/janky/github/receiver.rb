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

        if !valid_signature?
          return Rack::Response.new("Invalid signature", 403).finish
        end

        if @request.content_type != "application/json"
          return Rack::Response.new("Invalid Content-Type", 400).finish
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
        digest    = OpenSSL::Digest::SHA1.new
        signature = @request.env["HTTP_X_HUB_SIGNATURE"].split("=").last

        signature == OpenSSL::HMAC.hexdigest(digest, @secret, data)
      end

      def payload
        @payload ||= GitHub::Payload.parse(data)
      end

      def data
        @data ||= data!
      end

      def data!
        body = ""
        @request.body.each { |chunk| body << chunk }
        body
      end
    end
  end
end
