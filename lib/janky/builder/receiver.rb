module Janky
  module Builder
    class Receiver
      def self.call(env)
        request = Rack::Request.new(env)
        payload = Payload.parse(request.body)

        if payload.started?
          Build.start(payload.id, payload.url)
        elsif payload.completed?
          Build.complete(payload.id, payload.green?)
        else
          return Rack::Response.new("Bad Request", 400).finish
        end

        Rack::Response.new("OK", 201).finish
      end
    end
  end
end
