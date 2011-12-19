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

    end
  end
end
