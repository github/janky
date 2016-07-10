module Janky
  module Builder
    class Mock
      def initialize(green, app)
        @green    = green
        @app      = app
        @builds   = []
      end

      def run(params, create_url)
        params   = Yajl.load(params)["parameter"]
        param    = params.detect{ |p| p["name"] == "JANKY_ID" }
        build_id = param["value"]
        url      = create_url.to_s.gsub("build", build_id.to_s)

        @builds << [build_id, "#{url}/", @green]
      end

      def stop(stop_url)
        true
      end

      def output(build)
        "....FFFUUUUUUU"
      end

      def start
        @builds.each do |id, url, _|
          payload = Payload.start(id, url)
          request(payload)
        end
      end

      def complete
        @builds.each do |id, _, green|
          payload = Payload.complete(id, green)
          request(payload)
        end
        @builds.clear
      end

      def request(payload)
        Rack::MockRequest.new(@app).post("/_builder",
          :input => payload.to_json
        )
      end
    end
  end
end
