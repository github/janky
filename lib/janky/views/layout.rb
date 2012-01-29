module Janky
  module Views
    class Layout < Mustache

      def title
        "Janky Hubot"
      end

      def page_class
        nil
      end

      def root
        @request.env['SCRIPT_NAME']
      end

      def css_status_for(build)
        if build.green?
          "good"
        elsif build.building?
          "building"
        else
          "janky"
        end
      end

      def last_built_text_for(build)
        if build.building?
          "Build started <span class='relatize'>#{build.started_at}</span>…"
        elsif build.completed?
          "Built in <span>#{build.duration}</span> seconds"
        end
      end
    end
  end
end
