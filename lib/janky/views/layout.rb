# encoding: UTF-8
module Janky
  module Views
    class Layout < Mustache
      def title
        ENV["JANKY_PAGE_TITLE"] || "Janky Hubot"
      end

      def page_class
        nil
      end

      def root
        @request.env['SCRIPT_NAME']
      end

      def css_href
        ENV["JANKY_CSS_HREF"] || "/css/base.css"
      end

      def css_override_href
        ENV["JANKY_CSS_OVERRIDE_HREF"]
      end
    end
  end
end
