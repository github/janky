module Janky
  module Builder
    class Payload
      def self.parse(json, base_url)
        parsed = Yajl.load(json)
        build  = parsed["build"]

        full_url = build["full_url"]
        path = build["url"]
        build_url = full_url || "#{base_url}#{path}"

        new(
          build["phase"],
          build["parameters"]["JANKY_ID"],
          build_url,
          build["status"]
        )
      end

      def self.start(id, url)
        new("STARTED", id, url, nil)
      end

      def self.complete(id, green)
        status = (green ? "SUCCESS" : "FAILED")
        new("FINISHED", id, nil, status)
      end

      def initialize(phase, id, url, status)
        @phase      = phase
        @id         = id
        @url        = url
        @status     = status
      end

      attr_reader :id, :url

      def started?
        @phase == "STARTED"
      end

      def completed?
        @phase == "FINISHED" || @phase == "FINALIZED"
      end

      def green?
        if completed?
          @status == "SUCCESS"
        else
          false
        end
      end

      def to_json
        { :build => {
            :phase    => @phase,
            :status   => @status,
            :full_url => @url,
            :parameters => {
              "JANKY_ID" => @id
            }
          }
        }.to_json
      end
    end
  end
end
